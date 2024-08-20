#******************************************************************************
# Copyright (C) 2020-2022 Xilinx, Inc. All rights reserved.
# Copyright (C) 2022-2024 Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#******************************************************************************

source ./project.tcl
source ./dr.bd.tcl
source ./pfm_decls.tcl

#Generating Wrapper
make_wrapper -files [get_files ./vck190_power1.srcs/sources_1/bd/vck190_power1/vck190_power1.bd] -top
add_files -norecurse ./vck190_power1.srcs/sources_1/bd/vck190_power1/hdl/vck190_power1_wrapper.v

#Generating Target
generate_target all [get_files ./vck190_power1.srcs/sources_1/bd/vck190_power1/vck190_power1.bd]
update_compile_order -fileset sources_1
set_property top vck190_power1_wrapper [current_fileset]

# Generate simulation top for your entire design which would include
# aggregated NOC in the form of xlnoc.bd
generate_switch_network_for_noc


#Generating Emulation XSA
set_property platform.platform_state "pre_synth" [current_project]
file mkdir ./hw_emu
write_hw_platform -force -hw_emu -file ./hw_emu/hw_emu.xsa

#Calling Implementation for HW XSA
set_property platform.platform_state "impl" [current_project]
create_pr_configuration -name config_1 -partitions [list vck190_power1_i/slot0:slot0_inst_0 ]
create_pr_configuration -name config_2 -partitions { }  -greyboxes [list vck190_power1_i/slot0 ]
create_run child_1_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2024} -pr_config config_2
set_property PR_CONFIGURATION config_1 [get_runs impl_1]

set_property -name STEPS.PLACE_DESIGN.TCL.PRE -value [get_files -of_object [get_filesets utils_1] prohibit_select_bli_bels_for_hold.tcl] -objects [get_runs impl_1]

launch_runs synth_1 -jobs 20
wait_on_run synth_1

launch_runs impl_1 child_1_impl_1 -to_step write_device_image -jobs 10
wait_on_run impl_1 child_1_impl_1
open_run impl_1
file mkdir ./outputs

file copy -force ./vck190_power1.runs/impl_1/vck190_power1_wrapper.rcdo ./outputs/vck190_power1.rcdo
file copy -force ./vck190_power1.runs/impl_1/vck190_power1_wrapper.rnpi ./outputs/vck190_power1.rnpi

file copy -force ./vck190_power1.runs/impl_1/vck190_power1_wrapper.pdi ./outputs/vck190_power1.pdi
file delete -force ./outputs/gen_files
file copy -force ./vck190_power1.runs/impl_1/gen_files ./outputs/
file delete -force ./outputs/static_files
file copy -force ./vck190_power1.runs/impl_1/static_files ./outputs/
file copy -force ./vck190_power1.runs/child_1_impl_1/vck190_power1_i_slot0_greybox_partial.pdi ./outputs/greybox_partial.pdi
file copy -force ./vck190_power1.runs/child_1_impl_1/vck190_power1_i_slot0_greybox_partial.bif ./outputs/greybox_partial.bif

file copy -force ./hw_emu/hw_emu.xsa ./outputs/vck190_power1_hw_emu.xsa
set_property platform.board_id vck190_power1 [current_project]

set_property platform.ip_cache_dir [get_property ip_output_repo [current_project]] [current_project]


set_property platform.name vck190_power1 [current_project]

set_property platform.vendor "xilinx" [current_project]

set_property platform.version "1.0" [current_project]

write_hw_platform -force -fixed -hw -static -file ../hwflow_vck190_power1/outputs/vck190_power1_static.xsa
write_hw_platform -force -hw -rp vck190_power1_i/slot0 -file ../hwflow_vck190_power1/outputs/vck190_power1_rp_hw.xsa
validate_hw_platform -verbose ../hwflow_vck190_power1/outputs/vck190_power1_static.xsa
validate_hw_platform -verbose ../hwflow_vck190_power1/outputs/vck190_power1_rp_hw.xsa
open_checkpoint ../hwflow_vck190_power1/vck190_power1.runs/impl_1/vck190_power1_wrapper_routed_bb.dcp
write_device_image -force ../hwflow_vck190_power1/outputs/vck190_base_wrapper_out


