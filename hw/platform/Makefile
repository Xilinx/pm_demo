###############################################################################
# Copyright (C) 2019 - 2022 Xilinx, Inc.  All rights reserved.
# Copyright (C) 2024, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

BOARD = vck190
BASE_XSA = ../images/$(BOARD)_power1_rp_hw.xsa
PFM_PRJ_DIR = xsct/base/base/export/base
CURDIR = $(shell pwd)

all: create

create: ./base/base.xpfm

./base/base.xpfm: $(BASE_XSA)
	cp -r $(BASE_XSA) base.xsa
	xsct pfm.tcl -xsa base.xsa
	cp -rf $(PFM_PRJ_DIR) .


.PHONY: clean
clean:
	rm -rf *.xsa
	rm -rf base
	rm -rf .Xil
	rm -rf .*.bif boot image xsct
