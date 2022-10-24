###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################


#connect
#source boot.tcl
#boot_<mode>

#
# To set zcu102 to JTAG bootmode using XSDB/XSCT, add the following TCL scripts and call the function:
# Switch to JTAG boot mode #
#
proc boot_jtag { } {
	targets -set -filter {name =~ "PSU"}
	# update multiboot to ZERO
	mwr 0xffca0010 0x0
	# change boot mode to JTAG
	mwr 0xff5e0200 0x0100
	# reset
	rst -system
}


#
# Set zcu102 to SD bootmode using XSDB/XSCT
# Switch to SD boot mode #
#

proc boot_sd { } {
	targets -set -filter {name =~ "PSU"}
	# update multiboot to ZERO
	mwr 0xffca0010 0x0
	# change boot mode to SD
	mwr 0xff5e0200 0xE100
	# reset
	rst -system
	#A53 may be held in reset catch, start it with "con"
	after 2000
	con
}


#
# Set zcu102 to QSPI bootmode using XSDB/XSCT
# Switch to QSPI boot mode #
#
proc boot_qspi { } {
	targets -set -filter {name =~ "PSU"}
	# update multiboot to ZERO
	mwr 0xffca0010 0x0
	# change boot mode to QSPI
	mwr 0xff5e0200 0x2100
	# reset
	rst -system
	#A53 may be held in reset catch, start it with "con"
	after 2000
	con
}
targets -set -filter {name =~ "PSU" || name =~ "PS8"}
mwr 0xffff0000 0x14000000;
mask_write 0xFD1A0104 0x501 0x0
after 2000

#Disable security gates for PMU debugger
targets -set -filter {name =~ "PS8" || name =~ "PSU"}
mwr 0xffca0038 0x1FF

# Download pmufw.elf
target -set -filter {name =~ "MicroBlaze PMU"}
dow "pmufw.elf"
con
after 5000

# Select A53 Core 0
target -set -filter {name =~ "Cortex-A53 #0"}
stop
#rst -processor -clear-registers
dow "zynqmp_fsbl.elf"
con
after 5000
stop

target -set -filter {name =~ "Cortex-A53 #0"}
dow -data "system.dtb" 0x00100000
dow "u-boot.elf"
dow "bl31.elf"
after 2000
con
