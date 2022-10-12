###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################
#
# This file is the power-oob recipe.
#

SUMMARY = "Simple power-oob application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
#FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://power-oob \
        file://partial.pdi \
        file://greybox.pdi \
        file://power_demo.sh \
       "

S = "${WORKDIR}"

do_install() {
        echo "D: ${D}"
        echo "S: ${S}"
        install -d ${D}${bindir}
        install -m 0755 ${S}/partial.pdi    ${D}${bindir}
        install -m 0755 ${S}/greybox.pdi    ${D}${bindir}
        install -m 0755 ${S}/power_demo.sh  ${D}${bindir}
}

