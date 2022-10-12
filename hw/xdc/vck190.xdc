set_property PACKAGE_PIN AW27 [get_ports clk_p]
set_property IOSTANDARD LVDS15 [get_ports clk_p]
set_property PACKAGE_PIN AY27 [get_ports clk_n]
set_property IOSTANDARD LVDS15 [get_ports clk_n]

create_pblock pblock_slot0
add_cells_to_pblock [get_pblocks pblock_slot0] [get_cells -quiet [list vck190_power1_i/slot0]]
resize_pblock [get_pblocks pblock_slot0] -add {SLICE_X60Y0:SLICE_X359Y327}
resize_pblock [get_pblocks pblock_slot0] -add {BUFGCE_X3Y0:BUFGCE_X11Y23}
resize_pblock [get_pblocks pblock_slot0] -add {BUFGCTRL_X3Y0:BUFGCTRL_X11Y7}
resize_pblock [get_pblocks pblock_slot0] -add {BUFG_FABRIC_X0Y95:BUFG_FABRIC_X4Y0}
resize_pblock [get_pblocks pblock_slot0] -add {DSP58_CPLX_X0Y0:DSP58_CPLX_X5Y163}
resize_pblock [get_pblocks pblock_slot0] -add {DSP_X0Y0:DSP_X11Y163}
resize_pblock [get_pblocks pblock_slot0] -add {IOB_X28Y0:IOB_X104Y2}
resize_pblock [get_pblocks pblock_slot0] -add {MMCM_X3Y0:MMCM_X11Y0}
resize_pblock [get_pblocks pblock_slot0] -add {RAMB18_X2Y0:RAMB18_X11Y165}
resize_pblock [get_pblocks pblock_slot0] -add {RAMB36_X2Y0:RAMB36_X11Y82}
resize_pblock [get_pblocks pblock_slot0] -add {SLICE_X0Y191:SLICE_X69Y327}
resize_pblock [get_pblocks pblock_slot0] -add {IOB_X14Y3:IOB_X14Y13}
resize_pblock [get_pblocks pblock_slot0] -add {RAMB18_X0Y98:RAMB18_X1Y167}
resize_pblock [get_pblocks pblock_slot0] -add {RAMB36_X0Y49:RAMB36_X1Y83}
set_property SNAPPING_MODE ON [get_pblocks pblock_slot0]

set_property CLOCK_DEDICATED_ROUTE ANY_CMT_REGION [get_nets vck190_power1_i/slot0/CLK_WIZ_EVE_1/inst/clock_primitive_inst/clk_out1]

