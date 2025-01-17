#******************************************************************************
# © Copyright 2024 Xilinx, Inc.
# Copyright (C) 2025, Advanced Micro Devices, Inc.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#******************************************************************************


set rp_info_arg [list]

lappend rp_info_arg id
lappend rp_info_arg 0
lappend rp_info_arg hw
lappend rp_info_arg ../../images/vck190_power1_rp_hw.xsa
lappend rp_info_arg hw_emu
lappend rp_info_arg ../../images/vck190_power1_hw_emu.xsa

platform create -name base -desc " A base DFX platform targeting VCK190 which is the first Versal AI Core series evaluation kit, enabling designers to develop solutions using AI and DSP engines capable of delivering over 100X greater compute performance compared to current server class CPUs. This board includes 8GB of DDR4 UDIMM, 8GB LPDDR4 component, 400 AI engines, 1968 DSP engines, Dual-Core Arm® Cortex®-A72 and Dual-Core Cortex-R5. More information at https://www.xilinx.com/products/boards-and-kits/vck190.html" -hw ../../images/vck190_power1_static.xsa -rp $rp_info_arg -out ./ -no-boot-bsp

## Create the Linux domain
domain create -name linux -os linux -proc psv_cortexa72
domain config -generate-bif

## Create the aie domain
domain create -name aiengine -os aie_runtime -proc {ai_engine}

platform generate
