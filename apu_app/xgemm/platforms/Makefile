###############################################################################
# Copyright (C) 2019 - 2022 Xilinx, Inc.  All rights reserved.
# Copyright (C) 2024, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

BASE_XSA = ../../images.vck190/vck190_power1_rp_hw.xsa
all: create

create: $(BASE_PLATFORM)/export/base/base.xpfm

$(BASE_PLATFORM)/export/base/base.xpfm: $(BASE_XSA)
	cp -r $(BASE_XSA) base.xsa
	xsct platform_create.tcl


.PHONY: clean
clean:
	rm -rf *.xsa
	rm -rf base
	rm -rf .Xil
