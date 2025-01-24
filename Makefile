###############################################################################
# Copyright (C) 2023 - 2025, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

# Release version
RELEASE = 2024.2


# Targets, Dirs, XSA...
BOARD     = vck190
PLATFORM  = versal
BUILD_DIR = $(realpath .)/build.$(BOARD)
IMAGE_DIR = $(BUILD_DIR)/images
HW_XSA    = $(IMAGE_DIR)/$(BOARD)_power1.xsa
VER       ?= 202420.1

# Set paths from environment variables
PLNX_BSP      = $(PETALINUX_BSP)
PLNX_SETTINGS = $(PETALINUX_SETTINGS)
VITS_SETTINGS = $(VITIS_SETTINGS)


SHELL := /bin/bash


ifeq ($(BOARD),zcu102)
PLATFORM  = zynqmp
endif

# Set paths if environment variables empty
INSTALL_DIR   = /proj/petalinux/$(RELEASE)/petalinux-v$(RELEASE)_daily_latest
ifeq ($(PLNX_BSP),)
	PLNX_BSP      = $(INSTALL_DIR)/bsp/release/xilinx-$(BOARD)-v$(RELEASE)-final.bsp
endif

ifeq ($(PLNX_SETTINGS),)
	PLNX_SETTINGS = $(INSTALL_DIR)/tool/petalinux-v$(RELEASE)-final/settings.sh
endif

ifeq ($(VITS_SETTINGS),)
	VITS_SETTINGS = /proj/xbuilds/$(RELEASE)_daily_latest/installs/lin64/Vitis/$(RELEASE)/settings64.sh
endif
REL = $(shell expr $(PLNX_SETTINGS) | grep -Eo '([0-9]+)(\.?[0-9]+)*' | head -1)


#### Build all
all: hw_design platform overlay sdt xgemm petalinux rpu_app boot_image
.PHONY: all


#### Help
.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make'
	@echo '    hw_design platform overlay xgemm petalinux rpu_app boot_image'
	@echo ''
	@echo '  make hw_design'
	@echo '    Generate extensible xsa for VCK190 board'
	@echo ''
	@echo '  make platform'
	@echo '    Generate base platform for VCK190'
	@echo ''
	@echo '  make overlay'
	@echo '    Generate overlay (power + matrix_mul_thermal) for VCK190'
	@echo ''
	@echo '  make xgemm'
	@echo '    Build xgemm AIE application for VCK190'
	@echo ''
	@echo '  make sdt'
	@echo '    Build sdt for VCK190'
	@echo ''
	@echo '  make petalinux [BOARD=vck190|zcu102]'
	@echo '    Build linux images'
	@echo ''
	@echo '  make rpu_app [BOARD=vck190|zcu102]'
	@echo '    Build rpu_app'
	@echo ''
	@echo '  make boot_image [BOARD=vck190|zcu102]'
	@echo '    Generate BOOT.BIN'
	@echo ''
	@echo '  Defaults:'
	@echo '    RELEASE=$(RELEASE)'
	@echo '    BOARD=$(BOARD)'
	@echo '    PETALINUX_BSP=$(PLNX_BSP)'
	@echo '    PETALINUX_SETTINGS=$(PLNX_SETTINGS)'
	@echo '    VITIS_SETTINGS=$(VITS_SETTINGS)'
	@echo ''


#### Build hardware design (vck190)
.PHONY: hw_design
hw_design:
	echo $(REL)
	echo $(VITS_SETTINGS)

ifneq ($(BOARD),zcu102)
	mkdir -p $(IMAGE_DIR)
	cp -af hw/. $(BUILD_DIR)/hwflow_$(BOARD)_power1

	cd $(BUILD_DIR)/hwflow_$(BOARD)_power1 && \
	. $(VITS_SETTINGS) && \
	vivado -mode batch -source main.tcl -tclargs $(PLATFORM)-$(BOARD) $(VER) && \
	cd outputs && \
	sed -i -E 's/..\/hwflow_$(BOARD)_power1\/outputs\///' $(BOARD)_base_wrapper_out_pblock_slot0_partial.bif && \
	cp -rfv gen_files static_files	$(IMAGE_DIR) && \
	cp -rfv  $(BOARD)_base_wrapper_out.r*	$(IMAGE_DIR) && \
	cp -rfv *.xsa				$(IMAGE_DIR) && \
	cp -rfv $(IMAGE_DIR)/$(BOARD)_power1_static.xsa	$(HW_XSA) && \
	bootgen -arch $(PLATFORM) -image $(BOARD)_base_wrapper_out_pblock_slot0_partial.bif -w -o $(IMAGE_DIR)/greybox.pdi && \
	cp -fv ../$(BOARD)_power1.runs/impl_1/*_partial.pdi $(IMAGE_DIR)/partial.pdi
endif

#### Build platform
.PHONY: platform
platform:
ifeq ($(BOARD),vck190)
	echo $(REL)
	@echo $(VITS_SETTINGS)

	cp -rf hw/$@ $(BUILD_DIR)/
	. $(VITS_SETTINGS) && \
	cd $(BUILD_DIR)/$@ && \
	make BOARD=$(BOARD)
endif

#### Build overlay
.PHONY: overlay
overlay:
ifeq ($(BOARD),vck190)
	echo $(REL)
	@echo $(VITS_SETTINGS)

	cp -rf hw/$@ $(BUILD_DIR)
	cd $(BUILD_DIR)/$@ && \
	. $(VITS_SETTINGS) && \
	make -C matrix_mul_thermal BOARD=$(BOARD) PLATFORM=$(BUILD_DIR)/platform/base/base.xpfm && \
	cp -rfv matrix_mul_thermal/aie_matrix_multiplication.xclbin \
		$(IMAGE_DIR)/aie-matrix-multiplication.xclbin && \
	cp -rfv matrix_mul_thermal/BOOT.BIN \
		$(IMAGE_DIR)/partial.pdi
endif

#### Build AIE application (uses XSA from above builds)
.PHONY: xgemm
xgemm:
ifeq ($(BOARD),vck190)
	echo $(REL)
	echo $(VITS_SETTINGS)
	echo $(PLNX_SETTINGS)

	cp -rf apu_app/$@ $(BUILD_DIR)

	. $(VITS_SETTINGS) && \
	. $(PLNX_SETTINGS) && \
	cd $(BUILD_DIR)/$@ && \
	unset SYSROOT && \
	export SYSROOT=/proj/xbuilds/$(RELEASE)_daily_latest/internal_platforms/sw/versal/xilinx-versal-common-v$(RELEASE)/sysroots/cortexa72-cortexa53-xilinx-linux/ && \
	./build.sh
	cp -rfv $(BUILD_DIR)/$@/designs/xgemm-gmio/export/linux/aie-matrix-multiplication $(IMAGE_DIR)
endif

#### Build SDT
#sdtgen set_dt_param -board_dts MACHINE_NAME;
.PHONY: sdt
sdt:
ifneq ($(BOARD),zcu102)
	echo $(REL)
	echo $(HW_XSA)
	echo $(VITS_SETTINGS)

	rm -rf $(BUILD_DIR)/$@
	mkdir -p $(BUILD_DIR)/$@
	. $(VITS_SETTINGS) && \
	xsct -eval "setws .; \
	sdtgen set_dt_param \
		-xsa $(HW_XSA) \
		-board_dts versal-$(BOARD)-rev1.1 \
		-dir $(BUILD_DIR)/$@; \
	sdtgen generate_sdt"
endif

#### Build petalinux
.PHONY: petalinux
petalinux:
	echo $(REL)
	echo $(PLNX_BSP)
	echo $(PLNX_SETTINGS)

	mkdir -p $(IMAGE_DIR)/gen_files
	mkdir -p $(IMAGE_DIR)/static_files

ifeq ($(wildcard $(BUILD_DIR)/xilinx-$(BOARD)-$(REL)/.*),)
	cd $(BUILD_DIR) && \
	. $(PLNX_SETTINGS) && \
	petalinux-create -t project -s $(PLNX_BSP) && \
	cd xilinx-$(BOARD)-$(REL) && \
	$ [[ $(BOARD) = zcu102 ]] || petalinux-config --silentconfig --get-hw-description ../sdt/system-top.dts &&\
	$ [[ $(BOARD) = zcu102 ]] || cp $(HW_XSA) . && \
	sed -i -E 's/.*CONFIG_imagefeature-debug-tweaks.+/CONFIG_imagefeature-debug-tweaks=y/'				project-spec/configs/rootfs_config && \
	sed -i -E 's/.*CONFIG_imagefeature-serial-autologin-root.+/CONFIG_imagefeature-serial-autologin-root=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) != vck190 ]] || sed -i -E 's/.*CONFIG_zocl.+/CONFIG_zocl=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) != vck190 ]] || sed -i -E 's/.*CONFIG_xrt.+/CONFIG_xrt=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i -E 's/.*CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS.+/CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS=\"-DFSBL_A53_TCM_ECC_EXCLUDE_VAL=0\"/' project-spec/configs/config && \
	petalinux-config --silentconfig && \
	petalinux-create -t apps --template install --name power-demo --enable && \
	$ [[ $(BOARD) != vck190 ]] || cp -fv ../../apu_app/aie.dtbo	project-spec/meta-user/recipes-apps/power-demo/files && \
	cp -fv ../../apu_app/power_demo.sh	project-spec/meta-user/recipes-apps/power-demo/files && \
	cp -fv ../../apu_app/power-demo.bb	project-spec/meta-user/recipes-apps/power-demo && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv $(IMAGE_DIR)/{partial,greybox}.pdi	project-spec/meta-user/recipes-apps/power-demo/files && \
	$ [[ $(BOARD) != vck190 ]] || \
		cp -rfv $(IMAGE_DIR)/aie-matrix-multiplication*	project-spec/meta-user/recipes-apps/power-demo/files && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i '/.pdi/d' project-spec/meta-user/recipes-apps/power-demo/power-demo.bb && \
	$ [[ $(BOARD) = vck190  ]] || sed -i '/aie/d'  project-spec/meta-user/recipes-apps/power-demo/power-demo.bb
endif
	. $(PLNX_SETTINGS) && \
	cd $(BUILD_DIR)/xilinx-$(BOARD)-$(REL) && \
	petalinux-build && \
	cp -rfv images/linux/{bl31.elf,boot.scr,u-boot.elf,rootfs.cpio.gz.u-boot,Image}	\
			$(IMAGE_DIR) && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -fv images/linux/plm.elf \
			$(IMAGE_DIR)/gen_files && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -fv images/linux/psmfw.elf \
			$(IMAGE_DIR)/static_files && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv images/linux/system-default.dtb \
			$(IMAGE_DIR)/system.dtb && \
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv hardware/xilinx-$(BOARD)-$(REL)/outputs/project_1.xsa \
			$(IMAGE_DIR)/zcu102_power1.xsa && \
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv images/linux/{pmufw.elf,zynqmp_fsbl.elf,system.bit,system.dtb} \
			$(IMAGE_DIR)


#### Build RPU application (uses XSA from above builds)
.PHONY: rpu_app
rpu_app:
	echo $(REL)
	echo $(VITS_SETTINGS)

	mkdir -p $(IMAGE_DIR)
	mkdir -p $(BUILD_DIR)/$@
ifeq ($(wildcard $(BUILD_DIR)/rpu_app/.*),)
	. $(VITS_SETTINGS) && \
	cd $(BUILD_DIR)/$@ && \
	cp ../../$@/Makefile . && \
	make $@ BOARD=$(BOARD) BASE_XSA=$(HW_XSA)
else
	. $(VITS_SETTINGS) && \
	cd $(BUILD_DIR)/$@ && \
	make $@
endif
	cp -fv $(BUILD_DIR)/$@/$@/Debug/$@.elf $(IMAGE_DIR)


#### Build Boot Image
.PHONY: boot_image
boot_image:
	echo $(REL)
	echo $(VITS_SETTINGS)

	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv boards/$(BOARD)/$(BOARD)_board_topology.cdo \
			$(IMAGE_DIR)
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv boards/$(BOARD)/boot.tcl \
			$(IMAGE_DIR)
	cp -rfv boards/$(BOARD)/$(BOARD)_boot.bif $(IMAGE_DIR)

	cd $(IMAGE_DIR) && \
	. $(VITS_SETTINGS) && \
	bootgen -arch $(PLATFORM) -image $(BOARD)_boot.bif -w -o BOOT.BIN

#### Build SD Card Image
.PHONY: sd_image
sd_image:
	echo $(REL)
	echo $(VITS_SETTINGS)

	cd $(BUILD_DIR)/xilinx-$(BOARD)-$(REL) && \
	cp -fv images/linux/rootfs.tar.gz $(IMAGE_DIR) && \
	. $(VITS_SETTINGS) && \
	petalinux-package --wic -i ../images -o $(IMAGE_DIR) -r $(IMAGE_DIR) -b \
		"BOOT.BIN system.dtb Image rootfs.tar.gz"

# Start docker interactive shell
.PHONY: sh bash
sh bash:
	$@

# Clean
.PHONY: clean
clean:
	echo "nothing to clean ..."

# Delete
.PHONY: clobber
clober:
	rm -rf $(BUILD_DIR)

