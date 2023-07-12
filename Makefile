###############################################################################
# Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

# Release version
RELEASE = 2023.1


# Device, Targets, Dirs, XSA...
BOARD    = vck190
DEVICE    = xcvc1902
PLATFORM  = versal
BUILD_DIR = build
HW_PREFIX = xilinx-$(BOARD)
HW_XSA    = ../images/$(BOARD)_power1.xsa

# Set paths from environment variables
PLNX_BSP      = $(PETALINUX_BSP)
PLNX_SETTINGS = $(PETALINUX_SETTINGS)
VITS_SETTINGS = $(VITIS_SETTINGS)


# PDIs
BASE_PDI    = $(BOARD)_base_wrapper_out
PARTIAL_PDI = $(BOARD)_base_wrapper_out_pblock_slot0_partial

SHELL := /bin/bash

# Set paths if environment variables empty
INSTALL_DIR   = /proj/petalinux/$(RELEASE)/petalinux-v$(RELEASE)_daily_latest
ifeq ($(PLNX_BSP),)
	PLNX_BSP      = $(INSTALL_DIR)/bsp/release/$(HW_PREFIX)-v$(RELEASE)-final.bsp
endif

ifeq ($(PLNX_SETTINGS),)
	PLNX_SETTINGS = $(INSTALL_DIR)/tool/petalinux-v$(RELEASE)-final/settings.sh
endif

ifeq ($(VITS_SETTINGS),)
	VITS_SETTINGS = /proj/xbuilds/$(RELEASE)_daily_latest/installs/lin64/Vitis/$(RELEASE)/settings64.sh
endif
REL = $(shell expr $(PLNX_SETTINGS) | grep -Eo '([0-9]+)(\.?[0-9]+)*' | head -1)


# Set platform, device 
ifeq ($(BOARD),vck190)
	DEVICE = xcvc1902
	ifeq ($(shell expr $(REL) \<= 2022.1), 1)
		DEVICE = s80
	endif
else ifeq ($(BOARD),vmk180)
	DEVICE = xcvm1802
	ifeq ($(shell expr $(REL) \<= 2022.1), 1)
		DEVICE = s80
	endif
else ifeq ($(BOARD),zcu102)
	DEVICE = zcu102
	PLATFORM = zynqmp
else
	exit 1
endif

#### Build all
all: hw_design petalinux rpu_app boot_image
.PHONY: all


#### Help
.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make'
	@echo '    hw_design petalinux rpu_app boot_image'
	@echo ''
	@echo '  make hw_design [BOARD=vck190|vmk180]'
	@echo '    Generate extensible xsa for platform generation'
	@echo ''
	@echo '  make petalinux [BOARD=vck190|vmk180|zcu102]'
	@echo '    Build linux images'
	@echo ''
	@echo '  make rpu_app'
	@echo '    Build rpu_app'
	@echo ''
	@echo '  make boot_image'
	@echo '    Generate BOOT.BIN'
	@echo ''
	@echo '  Defaults:'
	@echo '    RELEASE=$(RELEASE)'
	@echo '    BOARD=$(BOARD)'
	@echo '    PETALINUX_BSP=$(PLNX_BSP)'
	@echo '    PETALINUX_SETTINGS=$(PLNX_SETTINGS)'
	@echo '    VITIS_SETTINGS=$(VITS_SETTINGS)'
	@echo ''


#### Build hardware design (vck190 or vmk180)
.PHONY: hw_design
hw_design:

	echo $(REL)
	echo $(DEVICE)
	echo $(BOARD)
	echo $(HW_PREFIX)
	echo $(VITS_SETTINGS)

ifeq ($(BOARD),zcu102)
	echo "No special design, using petalinux included hardware design"
	exit 0
endif
	mkdir -p $(BUILD_DIR)/images
	cp -af hw/. $(BUILD_DIR)/hwflow_$(BOARD)_power1

	cd $(BUILD_DIR)/hwflow_$(BOARD)_power1 && \
	$ [[ $(BOARD) = vck190 ]] || mv xdc/vck190.xdc xdc/$(BOARD).xdc && \
	$ [[ $(BOARD) = vck190 ]] || mv xdc/vck190_ddr4single_dimm1.xdc xdc/$(BOARD)_ddr4single_dimm1.xdc && \
	$ [[ $(BOARD) = vck190 ]] || find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/vck190/vmk180/g' && \
	$ [[ $(BOARD) = vck190 ]] || find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/vc1902/vm1802/g' && \
	. $(VITS_SETTINGS) && \
	vivado -mode batch -source main.tcl && \
	cd outputs && \
	cp -rfv gen_files			../../images/ && \
	cp -rfv static_files		../../images/ && \
	cp -fv $(BOARD)_power1.xsa	../../images && \
	sed -i -E 's/..\/hwflow_$(BOARD)_power1\/outputs\///' $(PARTIAL_PDI).bif && \
	cp -rfv gen_files			../../images && \
	cp -rfv static_files		../../images && \
	cp -fv $(BASE_PDI).rcdo		../../images && \
	cp -fv $(BASE_PDI).rnpi		../../images && \
	bootgen -arch $(PLATFORM) -image $(PARTIAL_PDI).bif -w -o ../../images/greybox.pdi && \
	cp -fv ../$(BOARD)_power1.runs/impl_1/$(BOARD)_power1_i_slot0_slot0_inst_0_partial.pdi ../../images/partial.pdi

#### Build petalinux
.PHONY: petalinux
petalinux:
	echo $(REL)
	echo $(HW_PREFIX)
	echo $(PLNX_BSP)
	echo $(PLNX_SETTINGS)

	mkdir -p $(BUILD_DIR)/images

ifeq ($(wildcard $(BUILD_DIR)/$(HW_PREFIX)-$(REL)/.*),)
	cd $(BUILD_DIR) && \
	. $(PLNX_SETTINGS) && \
	petalinux-create -t project -s $(PLNX_BSP) && \
	cd $(HW_PREFIX)-$(REL) && \
	$ [[ $(BOARD) = zcu102 ]] || cp $(HW_XSA) . && \
	cp ../../platform/uboot-env.vars project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i -E 's/versal/zynqmp/' project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h && \
	sed -i -E 's/.*CONFIG_imagefeature-debug-tweaks.+/CONFIG_imagefeature-debug-tweaks=y/'				project-spec/configs/rootfs_config && \
	sed -i -E 's/.*CONFIG_imagefeature-serial-autologin-root.+/CONFIG_imagefeature-serial-autologin-root=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i -E 's/.*CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS.+/CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS=\"-DFSBL_A53_TCM_ECC_EXCLUDE_VAL=0\"/' project-spec/configs/config && \
	petalinux-config --silentconfig && \
	$ [[ $(BOARD) = zcu102 ]] || petalinux-config --silentconfig --get-hw-description=./ && \
	petalinux-create -t apps --template install --name power-oob --enable && \
	cp -fv ../../apu_app/power-oob.bb	project-spec/meta-user/recipes-apps/power-oob && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv ../images/{partial,greybox}.pdi	project-spec/meta-user/recipes-apps/power-oob/files && \
	cp -rfv ../../apu_app/power_demo.sh	project-spec/meta-user/recipes-apps/power-oob/files && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i '/.pdi/d' project-spec/meta-user/recipes-apps/power-oob/power-oob.bb
endif
	. $(PLNX_SETTINGS) && \
	cd $(BUILD_DIR)/$(HW_PREFIX)-$(REL) && \
	petalinux-build && \
	$ [[ $(BOARD) = zcu102 ]]  || mkdir -p $(BUILD_DIR)/images/gen_files && \
	$ [[ $(BOARD) = zcu102 ]]  || mkdir -p $(BUILD_DIR)/images/static_files && \
	cp -rfv images/linux/{bl31.elf,boot.scr,u-boot.elf,rootfs.cpio.gz.u-boot,Image}				../images && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv images/linux/plm.elf							../images/gen_files && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv images/linux/psmfw.elf							../images/static_files/psm_fw.elf && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv images/linux/system-default.dtb						../images/system.dtb && \
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv hardware/$(HW_PREFIX)-$(REL)/outputs/project_1.xsa	../images/zcu102_power1.xsa && \
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv images/linux/{pmufw.elf,zynqmp_fsbl.elf,system.bit,system.dtb}	../images


#### Build RPU application (uses XSA from above builds)
.PHONY: rpu_app
rpu_app:
	echo $(REL)
	echo $(VITS_SETTINGS)

	mkdir -p $(BUILD_DIR)/images
ifeq ($(wildcard $(BUILD_DIR)/rpu_app/.*),)
	mkdir -p $(BUILD_DIR)/$@

	cd $(BUILD_DIR)/$@ && \
	. $(VITS_SETTINGS) && \
	cp ../../$@/Makefile . && \
	make $@ BOARD=$(BOARD) BASE_XSA=$(HW_XSA)
else
	. $(VITS_SETTINGS) && \
	cd $(BUILD_DIR)/$@ && \
	make $@
endif
	cp -fv $(BUILD_DIR)/$@/$@/Debug/$@.elf $(BUILD_DIR)/images


#### Build Boot Image
.PHONY: boot_image
boot_image:
	echo $(REL)
	echo $(HW_PREFIX)
	echo $(PLNX_SETTINGS)
	echo $(VITS_SETTINGS)

	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv platform/$(BOARD)/$(BOARD)_board_topology.cdo	$(BUILD_DIR)/images
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv platform/$(BOARD)/boot.tcl	$(BUILD_DIR)/images
	cp -rfv platform/$(BOARD)/$(BOARD)_boot.bif	$(BUILD_DIR)/images

	cd $(BUILD_DIR)/images && \
	. $(VITS_SETTINGS) && \
	. $(PLNX_SETTINGS) && \
	bootgen -arch $(PLATFORM) -image $(BOARD)_boot.bif -w -o BOOT.BIN

#### Build SD Card Image
.PHONY: sd_image
sd_image:
	echo $(REL)
	echo $(HW_PREFIX)
	echo $(PLNX_SETTINGS)
	echo $(VITS_SETTINGS)

	cd $(BUILD_DIR)/$(HW_PREFIX)-$(REL) && \
	cp -fv images/linux/rootfs.tar.gz ../images && \
	. $(VITS_SETTINGS) && \
	. $(PLNX_SETTINGS) && \
	petalinux-package --wic -i ../images -o ../images -r ../images -b "BOOT.BIN system.dtb Image rootfs.tar.gz"

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

