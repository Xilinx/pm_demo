#!/bin/bash

###############################################################################
# Copyright (C) 2025, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

echo "${PWD}"
export XILINXD_LICENSE_FILE=2100@aiengine-eng
export PFMS_DIR=${PWD}/platforms
export BASE_PLATFORM=${PFMS_DIR}/base
source settings.sh
cd designs/xgemm-gmio/
make clean
make AIEARCH=aie OS=linux
