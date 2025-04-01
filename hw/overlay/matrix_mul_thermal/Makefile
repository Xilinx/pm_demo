###############################################################################
# Copyright (C) 2025, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

YEAR = $(shell date '+%Y')
MONTH = $(shell date '+%m')
VERSION = 1.0

CURDIR = $(shell pwd)
SRC = $(CURDIR)/src

RM = rm -rf
MV = mv

PLATFORM ?=

PLATFORM_NAME = $(strip $(patsubst %.xpfm, % , $(shell basename $(PLATFORM))))


#include utils.mk

# v++ flags
VPP = v++
MK_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CUR_DIR := $(patsubst %/,%,$(dir $(MK_PATH)))
SRC_DIR = .

# setting devault value
TARGET ?= hw
TEMP_DIR := _x
TEMP_REPORT_DIR := $(CUR_DIR)/reports/_x
BUILD_REPORT_DIR := $(CUR_DIR)/reports
XCLBIN_DIR := $(CUR_DIR)/$(BUILD_DIR)
export XCL_BINDIR = $(XCLBIN_DIR)

## deb package script location
SILICON ?= prod
MAINTAINER = AMD
BOARD = ve2302
EXAMPLE = aie_matrix_multiplication
ifeq ($(SILICON),es1)
	BUILD_DIR = xrt-aie-test-$(BOARD)-$(SILICON)
else
	BUILD_DIR = xrt-aie-test-$(BOARD)
endif

# aie template
XILINX_VITIS_AIETOOLS ?=

ifneq ($(wildcard $(XILINX_VITIS)/aietools/.*),)
XILINX_VITIS_AIETOOLS := $(XILINX_VITIS)/aietools
else
XILINX_VITIS_AIETOOLS := $(XILINX_VITIS)/cardano
endif

# Setting customized_params in aiecompiler
############################ setting AIE Compiler ###########################

AIE_CXXFLAGS += --aie.verbose --aie.xlopt=0
AIE_CXXFLAGS += --report_dir $(TEMP_REPORT_DIR)
AIE_CXXFLAGS += -I $(XILINX_VITIS_AIETOOLS)/include
AIE_CXXFLAGS += -I $(SRC_DIR)/aie
AIE_CXXFLAGS += -I $(SRC_DIR)/aie/kernels
AIE_CXXFLAGS += -I ./

########################## Kernel compiler global settings ##########################
XO_FLAGS += --verbose --save-temps
XO_FLAGS += --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR)
XO_FLAGS += --clock.defaultFreqHz 200000000
XO_FLAGS += -I $(SRC_DIR)/pl_kernels
XO_FLAGS += -I $(XILINX_VITIS_AIETOOLS)/include

########################## Link & Package settings ########################################

VPP_LDFLAGS += --save-temps
VPP_LDFLAGS += --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR)
VPP_LDFLAGS += --config $(CUR_DIR)/system.cfg


VPP_PFLAGS +=  --save-temps
VPP_PFLAGS += --temp_dir $(TEMP_DIR) --report_dir $(TEMP_REPORT_DIR)
VPP_PFLAGS += --package.boot_mode=ospi
VPP_PFLAGS += --package.defer_aie_run

######################### binary container global settings ##########################

AIE_CONTAINER = aie/libadf.a
BINARY_CONTAINER_OBJS +=
BINARY_CONTAINER = $(EXAMPLE)
XSA_FILE = $(BINARY_CONTAINER).xsa
XCLBIN_FILE = $(BINARY_CONTAINER).xclbin

############################## Setting Targets ##############################

.PHONY: all xclbin
all: xclbin

xclbin: $(XCLBIN_FILE)

$(XCLBIN_FILE): $(XSA_FILE)
	$(VPP) -p -t $(TARGET) -f $(PLATFORM) $(AIE_CONTAINER) $(VPP_PFLAGS) -o $@ $^

$(XSA_FILE): $(BINARY_CONTAINER_OBJS) $(AIE_CONTAINER)
	$(VPP) -l $(VPP_LDFLAGS) -t $(TARGET) --platform $(PLATFORM) -o $@ $^

################ Setting Rules for Binary Containers (Building Kernels) ################

$(AIE_CONTAINER): $(SRC_DIR)/aie/xgemm.cpp
	@echo "Compiling: libadf.a"
	cd aie
	$(MAKE) all PFM_XPFM=$(PLATFORM) -C aie
	cd ../


.PHONY: help
help:
	@echo "Makefile Usage:"
	@echo "make all PLATFORM= <xpfm_file_location>"
	@echo "Command to build xclbin application"
	@echo ""
	@echo "make clean"
	@echo "Command to remove the generated files. "
	@echo ""


.PHONY: clean
clean:
	$(MAKE) clean -C aie
	$(RM) *xclbin.run_summary *.xclbin *.bin
	$(RM) *.bif *.xclbin.package_summary *.BIN
	$(RM) -rf xo_* _x*
	$(RM) -rf .Xil .ipcache .crashReporter
	$(RM) -rf $(CUR_DIR)/libadf.a  *.csv *.log sol.db
	$(RM) -rf .nfs* *.xsa *.ltx *.link_summary
	$(RM) -rf $(CUR_DIR)/Work  $(CUR_DIR)/reports $(BUILD_DIR)
	$(RM) -rf $(BUILD_DIR)

