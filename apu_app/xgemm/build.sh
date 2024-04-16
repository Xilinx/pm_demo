#!/bin/bash

###############################################################################
# Copyright (C) 2024, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

echo "${PWD}"
export XILINXD_LICENSE_FILE=2100@aiengine-eng
source /proj/petalinux/2024.1/petalinux-v2024.1_daily_latest/tool/petalinux-v2024.1-final/settings.sh
source /proj/xbuilds/2024.1_daily_latest/installs/lin64/Vitis/2024.1/settings64.sh
unset SYSROOT
export SYSROOT=/proj/xbuilds/2024.1_daily_latest/internal_platforms/sw/versal/xilinx-versal-common-v2024.1/sysroots/cortexa72-cortexa53-xilinx-linux/
export PFMS_DIR=${PWD}/platforms
export BASE_PLATFORM=${PFMS_DIR}/base
source settings.sh
cd designs/xgemm-gmio/
make clean
make AIEARCH=aie OS=linux
