###############################################################################
# Copyright (C) 2023- 2025, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################
#
# This file is the power-demo recipe.
#

SUMMARY = "Simple power-demo application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
#FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://power-demo \
		file://aie.dtbo \
		file://partial.pdi \
		file://greybox.pdi \
		file://aie-matrix-multiplication \
		file://aie-matrix-multiplication.xclbin \
		file://power_demo.sh \
		"

RDEPENDS:${PN} += " xrt \
		openssl \
			"
INSANE_SKIP:${PN} += " arch file-rdeps"

S = "${WORKDIR}"

do_install() {
	echo "D: ${D}"
	echo "S: ${S}"
	install -d ${D}${bindir}
	install -m 0755 ${S}/aie.dtbo                           ${D}/${bindir}
	install -m 0755 ${S}/partial.pdi                        ${D}/${bindir}
	install -m 0755 ${S}/greybox.pdi                        ${D}/${bindir}
	install -m 0755 ${S}/aie-matrix-multiplication          ${D}/${bindir}
	install -m 0755 ${S}/aie-matrix-multiplication.xclbin   ${D}/${bindir}
	install -m 0755 ${S}/power_demo.sh                      ${D}/${bindir}
}

