###############################################################################
# Copyright (C) 2023 - 2024, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

# Release version
RELEASE = 2024.1


# Device, Targets, Dirs, XSA...
BOARD     = vck190
DEVICE    = xcvc1902
PLATFORM  = versal
PLATFORM_NAME  = versal-vck190
BUILD_DIR = build
IMAGE_DIR = images.$(BOARD)
HW_PREFIX = xilinx-$(BOARD)
HW_XSA    = ../images.$(BOARD)/$(BOARD)_power1.xsa
VER              ?= 202410.1
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


# Set board, device 
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
	@echo '    Generate extensible xsa for board'
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
	mkdir -p $(BUILD_DIR)/$(IMAGE_DIR)
	cp -af hw/. $(BUILD_DIR)/hwflow_$(BOARD)_power1

	cd $(BUILD_DIR)/hwflow_$(BOARD)_power1 && \
	$ [[ $(BOARD) = vck190 ]] || mv xdc/vck190.xdc xdc/$(BOARD).xdc && \
	$ [[ $(BOARD) = vck190 ]] || find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/vck190/vmk180/g' && \
	$ [[ $(BOARD) = vck190 ]] || find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/vc1902/vm1802/g' && \
	. $(VITS_SETTINGS) && \
	vivado -mode batch -source main.tcl -tclargs $(PLATFORM_NAME) $(VER) && \
	cd outputs && \
	sed -i -E 's/..\/hwflow_$(BOARD)_power1\/outputs\///' $(PARTIAL_PDI).bif && \
	cp -rfv gen_files		../../$(IMAGE_DIR) && \
	cp -rfv static_files		../../$(IMAGE_DIR) && \
	cp -fv $(BASE_PDI).rcdo		../../$(IMAGE_DIR) && \
	cp -fv $(BASE_PDI).rnpi		../../$(IMAGE_DIR) && \
	cp -fv $(BOARD)_power1.xsa	../../$(IMAGE_DIR) && \
	bootgen -arch $(PLATFORM) -image $(PARTIAL_PDI).bif -w -o \
		../../$(IMAGE_DIR)/greybox.pdi && \
	cp -fv ../$(BOARD)_power1.runs/impl_1/*_partial.pdi \
		../../$(IMAGE_DIR)/partial.pdi

#### Build petalinux
.PHONY: petalinux
petalinux:
	echo $(REL)
	echo $(HW_PREFIX)
	echo $(PLNX_BSP)
	echo $(PLNX_SETTINGS)

	mkdir -p $(BUILD_DIR)/$(IMAGE_DIR)

ifeq ($(wildcard $(BUILD_DIR)/$(HW_PREFIX)-$(REL)/.*),)
	cd $(BUILD_DIR) && \
	. $(PLNX_SETTINGS) && \
	petalinux-create -t project -s $(PLNX_BSP) && \
	cd $(HW_PREFIX)-$(REL) && \
	$ [[ $(BOARD) = zcu102 ]] || cp $(HW_XSA) . && \
	cp ../../boards/uboot-env.vars project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i -E 's/versal/zynqmp/' project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h && \
	sed -i -E 's/.*CONFIG_imagefeature-debug-tweaks.+/CONFIG_imagefeature-debug-tweaks=y/'				project-spec/configs/rootfs_config && \
	sed -i -E 's/.*CONFIG_imagefeature-serial-autologin-root.+/CONFIG_imagefeature-serial-autologin-root=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) = zcu102 ]] || $ [[ $(BOARD) = vmk180 ]] || sed -i -E 's/.*CONFIG_zocl.+/CONFIG_zocl=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) = zcu102 ]] || $ [[ $(BOARD) = vmk180 ]] || sed -i -E 's/.*CONFIG_xrt.+/CONFIG_xrt=y/' project-spec/configs/rootfs_config && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i -E 's/.*CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS.+/CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS=\"-DFSBL_A53_TCM_ECC_EXCLUDE_VAL=0\"/' project-spec/configs/config && \
	petalinux-config --silentconfig && \
	$ [[ $(BOARD) = zcu102 ]] || petalinux-config --silentconfig --get-hw-description=./ && \
	petalinux-create -t apps --template install --name power-demo --enable && \
	cp -fv ../../apu_app/*	project-spec/meta-user/recipes-apps/power-demo/files && \
	mv -fv project-spec/meta-user/recipes-apps/power-demo/files/power-demo.bb	project-spec/meta-user/recipes-apps/power-demo && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv ../$(IMAGE_DIR)/{partial,greybox}.pdi	project-spec/meta-user/recipes-apps/power-demo/files && \
	$ [[ $(BOARD) != zcu102 ]] || sed -i '/.pdi/d' project-spec/meta-user/recipes-apps/power-demo/power-demo.bb
endif
	. $(PLNX_SETTINGS) && \
	cd $(BUILD_DIR)/$(HW_PREFIX)-$(REL) && \
	petalinux-build && \
	$ [[ $(BOARD) = zcu102 ]]  || mkdir -p $(BUILD_DIR)/$(IMAGE_DIR)/gen_files && \
	$ [[ $(BOARD) = zcu102 ]]  || mkdir -p $(BUILD_DIR)/$(IMAGE_DIR)/static_files && \
	cp -rfv images/linux/{bl31.elf,boot.scr,u-boot.elf,rootfs.cpio.gz.u-boot,Image}	\
			../$(IMAGE_DIR) && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -fv images/linux/plm.elf \
			../$(IMAGE_DIR)/gen_files && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -fv images/linux/psmfw.elf \
			../$(IMAGE_DIR)/static_files && \
	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv images/linux/system-default.dtb \
			../$(IMAGE_DIR)/system.dtb && \
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv hardware/$(HW_PREFIX)-$(REL)/outputs/project_1.xsa \
			../$(IMAGE_DIR)/zcu102_power1.xsa && \
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv images/linux/{pmufw.elf,zynqmp_fsbl.elf,system.bit,system.dtb} \
			../$(IMAGE_DIR)


#### Build RPU application (uses XSA from above builds)
.PHONY: rpu_app
rpu_app:
	echo $(REL)
	echo $(VITS_SETTINGS)

	mkdir -p $(BUILD_DIR)/$(IMAGE_DIR)
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
	cp -fv $(BUILD_DIR)/$@/$@/Debug/$@.elf $(BUILD_DIR)/$(IMAGE_DIR)


#### Build Boot Image
.PHONY: boot_image
boot_image:
	echo $(REL)
	echo $(HW_PREFIX)
	echo $(PLNX_SETTINGS)
	echo $(VITS_SETTINGS)

	$ [[ $(BOARD) = zcu102 ]]  || cp -rfv boards/$(BOARD)/$(BOARD)_board_topology.cdo \
			$(BUILD_DIR)/$(IMAGE_DIR)
	$ [[ $(BOARD) != zcu102 ]] || cp -rfv boards/$(BOARD)/boot.tcl \
			$(BUILD_DIR)/$(IMAGE_DIR)
	cp -rfv boards/$(BOARD)/$(BOARD)_boot.bif \
			$(BUILD_DIR)/$(IMAGE_DIR)

	cd $(BUILD_DIR)/$(IMAGE_DIR) && \
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
	cp -fv images/linux/rootfs.tar.gz ../$(IMAGE_DIR) && \
	. $(VITS_SETTINGS) && \
	. $(PLNX_SETTINGS) && \
	petalinux-package --wic -i ../images -o ../$(IMAGE_DIR) -r ../$(IMAGE_DIR) -b \
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

