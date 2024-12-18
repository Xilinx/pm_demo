##### Copyright (C) 2023 - 2024, Advanced Micro Devices, Inc.  All rights reserved.
##### SPDX-License-Identifier: MIT
# Versal Power Demo
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)
[![Introduction](https://img.shields.io/badge/-1._Introduction-informational)](#1-introduction)
[![Build Instructions](https://img.shields.io/badge/-2._Build_Instructions-critical)](#2-build-instructions)
[![Directory Structure](https://img.shields.io/badge/-3._Directory_Structure-yellowgreen)](#3-directory-structure)
[![Test](https://img.shields.io/badge/-4._Test-important)](#4-test)
[![Measured Power](https://img.shields.io/badge/-5._Measured_Power-success)](#5-measured-power)
[![Glossary](https://img.shields.io/badge/-6._Glossary-yellow)](#6-glossary)
[![References](https://img.shields.io/badge/-7._References-orange)](#7-references)
[![Docker](https://img.shields.io/badge/-8._Docker-grey)](#8-docker)


### 1. Introduction
This repository contains the source code needed to recreate, modify, and extend 
DFx boot power demo to demonstrate Versal/ZynqMP devices various power modes. It
demonstrates below power modes on vck190/vmk180/zcu102 boards.
```
 1. APU, RPU, PL load (typical max power mode)
 2. APU and RPU full load, PL in low power (PS max power mode)
 3. APU full load, RPU idle, PL in low power
 4. APU (APU0 only) full load, RPU idle, PL in low power
 5. APU (APU0 low freq 300MHz) full, RPU idle, PL in low power
 6. APU Linux Idle, RPU idle, PL in low power (Linux Idle)
 7. APU suspended with FPD ON, RPU idle, PL in low power
 8. APU suspended with FPD OFF, RPU full load, PL in low power
 9. APU suspended with FPD OFF, RPU idle, PL in low power
10. APU suspended with FPD OFF, RPU suspended, PL in low power
```

To build sample designs from source code in this repository, you will need to have the
following tools installed and follow the [build instructions](#2-build-instructions):

- A Linux-based host OS supported by Vitis and PetaLinux with about 100GB free
  disk space
- AMD VCK190 or VMK180 or ZCU102 board
- [Vitis][1] 202x.x
- [PetaLinux][2] 202x.x

[1]: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vitis.html
[2]: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html

<b>VCK190/VMK180 Board:</b>
![VCK190/VMK180 Board](https://www.xilinx.com/content/xilinx/en/products/boards-and-kits/vck190/_jcr_content/root/fullParsys/xilinxflexibleslab_1080182232/xilinxflexibleslab-parsys/xilinxtabs2/childParsys-specifications/xilinximage_352e.img.jpg/1624489781894.jpg)

<b>Versal Power Domains:</b>
![Power domains](https://docs.xilinx.com/api/khub/maps/YkshAdoNzkNbQqwk6DJygA/resources/_WE2KjhPlWqMylR2Hezu1g/content?Ft-Calling-App=ft%2Fturnkey-portal&Ft-Calling-App-Version=4.1.22)

<b>ZCU102 Board:</b>
![ZCU102 Board](https://www.xilinx.com/content/xilinx/en/products/boards-and-kits/ek-u1-zcu102-g/_jcr_content/root/fullParsys/xilinxflexibleslab_749886269/xilinxflexibleslab-parsys/xilinxtabs2_copy/childParsys-specifications/xilinximage.img.jpg/1519410010855.jpg)

### 2. Build Instructions
```
Defaults:
 RELEASE=2024.2
 BOARD=vck190
 PETALINUX_BSP=/proj/petalinux/2024.2/petalinux-v2024.2_daily_latest/bsp/release/xilinx-vck190-v2024.2-final.bsp
 PETALINUX_SETTINGS=/proj/petalinux/2024.2/petalinux-v2024.2_daily_latest/tool/petalinux-v2024.2-final/settings.sh
 VITIS_SETTINGS=/proj/xbuilds/2024.2_daily_latest/installs/lin64/Vitis/2024.2/settings64.sh
 Note: Change Makefile variable RELEASE=202x.x to build for a different release version.
```
Vitis and PetaLinux tools need to be installed before building any design.
```bash
export PETALINUX_BSP=<PetaLinux BSP path>
export PETALINUX_SETTINGS=<PetaLinux install path>/settings.sh
export VITIS_SETTINGS=<Vitis_install_path>/Vitis/202x.x/settings64.sh
./settings.sh	# Verify environment variable settings in a shell session
```

Use make to build hardware design, petalinux, rpu application and boot image for `BOARD=[vck190|vmk180|zcu102]`.
The final artifacts will be in the build/images folder. Delete build artifacts folders build or build\hwflow_xxx, build\rpu_app, build\xilinx-xxx for a clean build.<br>
`Note:` It will take several hours (> 6 hours) to build all components.
- `make help`
- `make`
    or
- `make BOARD=[vck190|vmk180|zcu102]`
    or
- `make hw_design BOARD=[vck190|vmk180]`
- `make xgemm BOARD=[vck190]`
- `make petalinux BOARD=[vck190|vmk180|zcu102]`
- `make rpu_app BOARD=[vck190|vmk180|zcu102]`
- `make boot_image BOARD=[vck190|vmk180|zcu102]`

### 3. Directory Structure
```
.pm_demo
├── apu_app - APU
│   └── xgemm - AIE application
│       ├── designs
│       │   └── xgemm-gmio
│       │       ├── aie
│       │       │   └── kernels
│       │       ├── hw
│       │       ├── ps
│       │       │   └── linux
│       │       └── sw
│       └── platforms
├── boards
│   ├── vck190
│   ├── vmk180
│   └── zcu102
├─ build - Build artifacts
│   ├─ ...
│   └─ images.(BOARD) - Contains all build images
├── hw
│   ├── ip
│   │   ├── bufg_ctrl
│   │   │   ├── src
│   │   │   └── xgui
│   │   └── power
│   │       ├── src
│   │       │   ├── vio_bram
│   │       │   └── vio_top_logic
│   │       └── xgui
│   └── xdc
│       └── qor_scripts
├── overlays
│   ├── matrix_mul_thermal
│   │   └── aie
│   │       └── kernels
│   └── matrix_mul_thermal_auto
│       └── aie
│           └── kernels
├── platforms
└── rpu_app - RPU application
├── Dockerfile
├── LICENSE
├── Makefile
├── README.md
├── settings.sh  - Verify petalinux, vitis paths
└── xmake        - Docker make file (petalinux only for now)
```
### 4. Test
<b>SD mode:</b>
    Copy `BOOT.BIN, system.dtb, Image and rootfs.cpio.gz.u-boot` files to a bootable FAT32 formatted SD Card.
    Power up the board. Use a terminal application to open console <T1:com0> and <T2:com2>(115200 8N1) connected to the board.
<b>jtag mode:</b>
    Open a xsdb console <T3> connected to the board.
-   Setup tftp server `"<path to Image...>"`
-   T3: xsdb% `cd {<path to Image...>}`
-   T3: xsdb% `device program BOOT.BIN`       <b>zcu102:</b> xsdb% `source boot.tcl`
-   T1: Stop auto boot by <Enter key> at the u-boot prompt [Versal | ZynqMP]
-   T1: [Versal | ZynqMP]> `run wr_sdboot`
-   T1: Power cycle the board and set bootmode to `sd_ls`
-   T3: <b>zcu102:</b>xsdb% `boot_sd`
-   T1: Stop auto boot by <Enter key> at u-boot prompt [Versal | ZynqMP]
-   T1: [Versal | ZynqMP]> `run bt_tftp`
-   Once petalinux is up, run the demo<br>    root@xilinx-vck190-2022301:~# `sudo power_demo.sh`
-   Check the power rail values from the System controller on <T2> console<br>    T2: `sc_app -c listpower` <br> T2: `sc_app -c getpower -t VCC_PSFP`

## 5. Measured Power
---
 <font size="1"> 

| Power State | Description | PLD<br>Power<br>(W)|FPD<br>Power<br>(W)|LPD<br>Power<br>(W)|SoC<br>Power<br>(W)|PMC<br>Power<br>(W)|BBRAM<br>Power<br>(W)|Total<br>Power<br>(W)|
| :---------- | :---------- | :----------: | :----------: | :----------: | :----------: | :----------: | :-------------: | :------------: |
|APU, RPU, PL full load (Max typical power)					|FPD, LPD and PLD in high power mode	 |29.6781|0.4737|0.1328|3.5625|0.1070|0.1070|34.0611|
|APU and RPU full load, PL in low power						|R5s Active, A72s Active				 | 3.6039|0.4737|0.1314|3.4965|0.1078|0.1070| 7.9203|
|APU full load, RPU idle, PL in low power					|R5s Idle, A72s Active					 | 3.5556|0.4717|0.1238|3.4803|0.1049|0.1077| 7.8444|
|APU (APU0 only) full load, RPU idle, PL in low power		|R5s Idle, 1 A72 Active					 | 3.6039|0.3676|0.1234|3.4682|0.1050|0.1063| 7.7744|
|APU (APU0 low freq 300MHz) full, RPU idle, PL in low power	|R5s Idle, APU0 300MHz					 | 4.2021|0.1679|0.1234|3.4682|0.1050|0.1071| 8.1737|
|APU Linux Idle, RPU idle, PL in low power					|R5s Idle, 1 A72 Idle					 | 3.7007|0.1770|0.1230|3.4642|0.1065|0.1077| 7.6791|
|APU suspended with FPD ON, RPU idle, PL in low power		|R5s Idle, A72s Off, DDR Self Refresh	 | 3.2603|0.3175|0.1127|3.4561|0.1026|0.1070| 7.3562|
|APU suspended with FPD OFF, RPU full load, PL in low power	|R5s Active, FPD Off					 | 4.0151|     0|0.1270|3.4521|0.0990|0.0830| 7.7762|
|APU suspended with FPD OFF, RPU idle, PL in low power		|R5s Idle, FPD Off, DDR Self Refresh	 | 3.5556|     0|0.1113|3.4642|0.1033|0.0838| 7.3182|
|APU suspended with FPD OFF, RPU suspended, PL in low power	|R5s suspended, FPD Off, DDR Self Refresh| 3.4776|     0|0.1131|3.4642|0.1005|0.0830| 7.2384|


Latency:
| Power State Transition						   | Latency (ms)|Notes	|
| :----------------------------------------------- | :----------:|:---	|
|PL high power → PL low power								| 284|		|
|APU1 ON → APU1 OFF											|  47|		|
|APU0 high freq → APU0 low freq								|   0|		|
|Linux full load → Linux Idle								|  57|		|
|Linux Idle (APU0 low freq) → Linux Suspended with FPD ON	| 132|		|
|Linux Suspended with FPD ON → Linux Suspended with FPD OFF	|6.85|		|
|Linux Suspended with FPD OFF → Linux Suspended with FPD ON	|   0|		|
|Linux Suspended with FPD ON → APU0 WakeUp					| 430|		|
|APU0 WakeUp → Linux resume (APU0 low freq)					| 273|		|
|APU0 low freq → APU0 high freq								|  ~0|		|
|APU1 OFF → APU1 ON											| 123|		|
|Linux Idle → Linux full load								|  NA|		|
|PL low power → PL high power								| 542|		|


</font>

## 6. Glossary
| Name| Description					|
| :---| :-------------------------- |
| AIE | Adaptable Intelligent Engine|
| APU | Application Processing Unit |
| FPD | Full Power Domain 			|
| LPD | Low Power Domain 			|
| RPU | Realtime Processing Unit	|
| PL  | Programmable Logic			|
| PLD | Programmable Logic Domain	|

## 7. References
[versal-acap-trm]:	https://docs.xilinx.com/r/en-US/am011-versal-acap-trm/Introduction
[zynqmp-trm]:		https://docs.xilinx.com/r/en-US/ug1085-zynq-ultrascale-trm/Zynq-UltraScale-Device-Technical-Reference-Manual
[vck190-eval-bd]:	https://docs.xilinx.com/r/en-US/ug1366-vck190-eval-bd
[vmk180-eval-bd]:	https://docs.xilinx.com/r/en-US/ug1411-vmk180-eval-bd
[zcu102-eval-bd]:	https://docs.xilinx.com/v/u/en-US/ug1182-zcu102-eval-bd
1. [Versal ACAP Technical Reference Manual][versal-acap-trm]<br>
2. [Zynq UltraScale+ Device Technical Reference Manual][zynqmp-trm]
3. [VCK190 Evaluation Board User Guide][vck190-eval-bd]
4. [VMK180 Evaluation Board User Guide][vmk180-eval-bd]
5. [ZCU102 Board User Guide][zcu102-eval-bd]
8. <b>Docker<b>
    ##### Install and setup docker
    - curl -fsSL https://get.docker.com -o get-docker.sh
    - `sh get-docker.sh`
    - `sudo groupadd docker`
    - `sudo usermod -aG docker ${USER}`  
      <b>`Note:`</b> This might require logout and log back in 
    - `sudo systemctl start docker`
    - `sudo chmod 777 /var/run/docker.sock`<br>
      <b>`Note:`</b> This may be needed if there is a permission denied error

    ##### Helpful docker commands
    - Restart docker:&emsp;&emsp;&emsp;&emsp;`sudo systemctl restart docker`
    - List images:&ensp;&emsp;&emsp;&emsp;&emsp;&emsp;`docker images ls`
    - Stop docker containers:&nbsp;`docker stop $(docker ps -a -q)`
    - Delete all images: &emsp;&emsp;&emsp;`docker system prune -a`
