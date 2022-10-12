#!/bin/bash
###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

if [[ -z "$VITIS_SETTINGS" ]]; then
	echo "[ERROR]: Vitis settings needs to be setup"
	return
fi

if [[ -z "$PETALINUX_SETTINGS" ]]; then
	echo "[ERROR]: PetaLinux settings needs to be setup"
	return
fi

if [ -z "$PETALINUX_BSP" ]  && [ -z "$SYSROOT" ]; then
	echo "[ERROR]: Petalinux BSP path must be set"
	return
fi
