###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

# Release version
RELEASE = 2022.2


# Device, Targets, Dirs, XSA...
TARGET    = vck190
DEVICE    = xcvc1902
PLATFORM  = versal
BUILD_DIR = build
HW_PREFIX = xilinx-$(TARGET)
HW_XSA    = ../images/$(TARGET)_power1.xsa

# Set paths from environment variables
PLNX_BSP      = $(PETALINUX_BSP)
PLNX_SETTINGS = $(PETALINUX_SETTINGS)
VITS_SETTINGS = $(VITIS_SETTINGS)


# PDIs
BASE_PDI    = $(TARGET)_base_wrapper_out
PARTIAL_PDI = $(TARGET)_base_wrapper_out_pblock_slot0_partial

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
ifeq ($(TARGET),vck190)
	DEVICE = xcvc1902
	ifeq ($(shell expr $(REL) \<= 2022.1), 1)
		DEVICE = s80
	endif
else ifeq ($(TARGET),vmk180)
	DEVICE = xcvm1802
	ifeq ($(shell expr $(REL) \<= 2022.1), 1)
		DEVICE = s80
	endif
else ifeq ($(TARGET),zcu102)
	DEVICE = zcu102
	PLATFORM = zynqmp
else
	exit 1
endif

#### Help
.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make'
	@echo '    hw_design petalinux rpu_app boot_image'
	@echo ''
	@echo '  make hw_design [TARGET=vck190|vmk180]'
	@echo '    Generate extensible xsa for platform generation'
	@echo ''
	@echo '  make petalinux [TARGET=vck190|vmk180|zcu102]'
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
	@echo '    TARGET=$(TARGET)'
	@echo '    PETALINUX_BSP=$(PLNX_BSP)'
	@echo '    PETALINUX_SETTINGS=$(PLNX_SETTINGS)'
	@echo '    VITIS_SETTINGS=$(VITS_SETTINGS)'
	@echo ''


#### Build all
all: hw_design petalinux rpu_app boot_image
.PHONY: all

#### Build hardware design (vck190 or vmk180)
.PHONY: hw_design
hw_design:

	echo $(REL)
	echo $(DEVICE)
	echo $(TARGET)
	echo $(HW_PREFIX)
	echo $(VITS_SETTINGS)

ifeq ($(TARGET),zcu102)
	echo "No special design, using petalinux included hardware design"
	exit 0
endif
	mkdir -p $(BUILD_DIR)/images
	cp -af hw/. $(BUILD_DIR)/hwflow_$(TARGET)_power1

	cd $(BUILD_DIR)/hwflow_$(TARGET)_power1 && \
	$ [[ $(TARGET) = vck190 ]] || mv xdc/vck190.xdc xdc/$(TARGET).xdc && \
	$ [[ $(TARGET) = vck190 ]] || mv xdc/vck190_ddr4single_dimm1.xdc xdc/$(TARGET)_ddr4single_dimm1.xdc && \
	$ [[ $(TARGET) = vck190 ]] || find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/vck190/vmk180/g' && \
	$ [[ $(TARGET) = vck190 ]] || find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/vc1902/vm1802/g' && \
	. $(VITS_SETTINGS) && \
	vivado -mode batch -source main.tcl && \
	cd outputs && \
	cp -fv $(TARGET)_power1.xsa	../../images && \
	cdoutil -annotate -device $(DEVICE) -output-file $(BASE_PDI).rnpi.txt $(BASE_PDI).rnpi && \
	sed -i -E 's/pm_init_node 0x18700000 0x1 0x4214004 0x4220006/pm_init_node 0x18700000 0x1 0x4214004/' $(BASE_PDI).rnpi.txt && \
	cdoutil -annotate -device $(DEVICE) -output-file $(PARTIAL_PDI)_mask.rcdo.txt $(PARTIAL_PDI)_mask.rcdo && \
	sed -i '/pm_init_node 0x18700002 0x1 0x4220006/d' $(PARTIAL_PDI)_mask.rcdo.txt && \
	cdoutil -annotate -device $(DEVICE) -output-file $(PARTIAL_PDI)_mask.rnpi.txt $(PARTIAL_PDI)_mask.rnpi && \
	sed -i -E 's/pm_init_node 0x18700002 0x1 0x4214004 0x4220006/pm_init_node 0x18700002 0x1/' $(PARTIAL_PDI)_mask.rnpi.txt && \
	sed -i -E 's/$(PARTIAL_PDI)_mask.rcdo.*/$(PARTIAL_PDI)_mask.rcdo.txt/' $(PARTIAL_PDI).bif && \
	sed -i -E 's/$(PARTIAL_PDI)_mask.rnpi.*/$(PARTIAL_PDI)_mask.rnpi.txt/' $(PARTIAL_PDI).bif && \
	sed -i -E 's/..\/hwflow_$(TARGET)_power1\/outputs\///' $(PARTIAL_PDI).bif && \
	cp -rfv gen_files			../../images && \
	cp -rfv static_files		../../images && \
	cp -fv $(BASE_PDI).rcdo		../../images && \
	cp -fv $(BASE_PDI).rnpi.txt	../../images && \
	bootgen -arch $(PLATFORM) -image $(PARTIAL_PDI).bif -w -o ../../images/greybox.pdi && \
	cp -fv ../$(TARGET)_power1.runs/impl_1/$(TARGET)_power1_i_slot0_slot0_partial.pdi	../../images/partial.pdi

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
	$ [[ $(TARGET) = zcu102 ]] || cp $(HW_XSA) . && \
	cp ../../platform/uboot-env.vars project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h && \
	$ [[ $(TARGET) != zcu102 ]] || sed -i -E 's/versal/zynqmp/' project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h && \
	sed -i -E 's/.*CONFIG_auto-login.+/CONFIG_auto-login=y/' project-spec/configs/rootfs_config && \
	$ [[ $(TARGET) != zcu102 ]] || sed -i -E 's/.*CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS.+/CONFIG_SUBSYSTEM_FSBL_COMPILER_EXTRA_FLAGS=\"-DFSBL_A53_TCM_ECC_EXCLUDE_VAL=0\"/' project-spec/configs/config && \
	petalinux-config --silentconfig && \
	petalinux-create -t apps --template install --name power-oob --enable && \
	cp -fv ../../apu_app/power-oob.bb	project-spec/meta-user/recipes-apps/power-oob && \
	$ [[ $(TARGET) = zcu102 ]]  || cp -rfv ../images/{partial,greybox}.pdi	project-spec/meta-user/recipes-apps/power-oob/files && \
	cp -rfv ../../apu_app/power_demo.sh	project-spec/meta-user/recipes-apps/power-oob/files && \
	$ [[ $(TARGET) != zcu102 ]] || sed -i '/.pdi/d' project-spec/meta-user/recipes-apps/power-oob/power-oob.bb
endif
	. $(PLNX_SETTINGS) && \
	cd $(BUILD_DIR)/$(HW_PREFIX)-$(REL) && \
	petalinux-build && \
	cp -rfv images/linux/{bl31.elf,boot.scr,u-boot.elf,rootfs.cpio.gz.u-boot,Image}				../images && \
	$ [[ $(TARGET) = zcu102 ]]  || cp -rfv images/linux/plm.elf									../images/gen_files && \
	$ [[ $(TARGET) = zcu102 ]]  || cp -rfv images/linux/psmfw.elf								../images/static_files/psm_fw.elf && \
	$ [[ $(TARGET) = zcu102 ]]  || cp -rfv images/linux/system-default.dtb						../images/system.dtb && \
	$ [[ $(TARGET) != zcu102 ]] || cp -rfv hardware/$(HW_PREFIX)-$(REL)/outputs/project_1.xsa	../images/zcu102_power1.xsa && \
	$ [[ $(TARGET) != zcu102 ]] || cp -rfv images/linux/{pmufw.elf,zynqmp_fsbl.elf,system.bit,system.dtb}	../images


#### Build RPU application (uses XSA from above builds)
.PHONY: rpu_app
rpu_app:
	echo $(REL)
	echo $(VITS_SETTINGS)

	mkdir -p $(BUILD_DIR)/images
ifeq ($(wildcard $(BUILD_DIR)/rpu_app/.*),)
	mkdir -p $(BUILD_DIR)/rpu_app

	export BASE_XSA=$(HW_XSA) && \
	export TARGET_BOARD=$(TARGET) && \
	cd $(BUILD_DIR)/rpu_app && \
	. $(VITS_SETTINGS) && \
	cp ../../rpu_app/Makefile . && \
	make init
endif
	. $(VITS_SETTINGS) && \
	cd $(BUILD_DIR)/rpu_app && \
	make app && \
	cp -fv rpu_app/Debug/rpu_app.elf ../images


#### Build Boot Image
.PHONY: boot_image
boot_image:
	echo $(REL)
	echo $(HW_PREFIX)
	echo $(PLNX_SETTINGS)
	echo $(VITS_SETTINGS)

	$ [[ $(TARGET) = zcu102 ]]  || cp -rfv platform/vck_vmk_board_topology.cdo	$(BUILD_DIR)/images
	$ [[ $(TARGET) != zcu102 ]] || cp -rfv platform/$(TARGET)/boot.tcl	$(BUILD_DIR)/images
	cp -rfv platform/$(TARGET)/$(TARGET)_boot.bif	$(BUILD_DIR)/images

	cd $(BUILD_DIR)/images && \
	. $(VITS_SETTINGS) && \
	. $(PLNX_SETTINGS) && \
	bootgen -arch $(PLATFORM) -image $(TARGET)_boot.bif -w -o BOOT.BIN

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

