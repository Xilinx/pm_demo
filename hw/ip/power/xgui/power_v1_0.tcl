###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################
# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DATAWIDTH_18K" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATAWIDTH_36K" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_LOGIC_BLOCKS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_RAMB_18_DC" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_RAMB_36_DC" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Numbr_of_DSP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "dsize" -parent ${Page_0}
  ipgui::add_param $IPINST -name "nbtap" -parent ${Page_0}


}

proc update_PARAM_VALUE.DATAWIDTH_18K { PARAM_VALUE.DATAWIDTH_18K } {
	# Procedure called to update DATAWIDTH_18K when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATAWIDTH_18K { PARAM_VALUE.DATAWIDTH_18K } {
	# Procedure called to validate DATAWIDTH_18K
	return true
}

proc update_PARAM_VALUE.DATAWIDTH_36K { PARAM_VALUE.DATAWIDTH_36K } {
	# Procedure called to update DATAWIDTH_36K when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATAWIDTH_36K { PARAM_VALUE.DATAWIDTH_36K } {
	# Procedure called to validate DATAWIDTH_36K
	return true
}

proc update_PARAM_VALUE.NUM_LOGIC_BLOCKS { PARAM_VALUE.NUM_LOGIC_BLOCKS } {
	# Procedure called to update NUM_LOGIC_BLOCKS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_LOGIC_BLOCKS { PARAM_VALUE.NUM_LOGIC_BLOCKS } {
	# Procedure called to validate NUM_LOGIC_BLOCKS
	return true
}

proc update_PARAM_VALUE.NUM_RAMB_18_DC { PARAM_VALUE.NUM_RAMB_18_DC } {
	# Procedure called to update NUM_RAMB_18_DC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_RAMB_18_DC { PARAM_VALUE.NUM_RAMB_18_DC } {
	# Procedure called to validate NUM_RAMB_18_DC
	return true
}

proc update_PARAM_VALUE.NUM_RAMB_36_DC { PARAM_VALUE.NUM_RAMB_36_DC } {
	# Procedure called to update NUM_RAMB_36_DC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_RAMB_36_DC { PARAM_VALUE.NUM_RAMB_36_DC } {
	# Procedure called to validate NUM_RAMB_36_DC
	return true
}

proc update_PARAM_VALUE.Numbr_of_DSP { PARAM_VALUE.Numbr_of_DSP } {
	# Procedure called to update Numbr_of_DSP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Numbr_of_DSP { PARAM_VALUE.Numbr_of_DSP } {
	# Procedure called to validate Numbr_of_DSP
	return true
}

proc update_PARAM_VALUE.dsize { PARAM_VALUE.dsize } {
	# Procedure called to update dsize when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.dsize { PARAM_VALUE.dsize } {
	# Procedure called to validate dsize
	return true
}

proc update_PARAM_VALUE.nbtap { PARAM_VALUE.nbtap } {
	# Procedure called to update nbtap when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.nbtap { PARAM_VALUE.nbtap } {
	# Procedure called to validate nbtap
	return true
}


proc update_MODELPARAM_VALUE.NUM_LOGIC_BLOCKS { MODELPARAM_VALUE.NUM_LOGIC_BLOCKS PARAM_VALUE.NUM_LOGIC_BLOCKS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_LOGIC_BLOCKS}] ${MODELPARAM_VALUE.NUM_LOGIC_BLOCKS}
}

proc update_MODELPARAM_VALUE.NUM_RAMB_36_DC { MODELPARAM_VALUE.NUM_RAMB_36_DC PARAM_VALUE.NUM_RAMB_36_DC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_RAMB_36_DC}] ${MODELPARAM_VALUE.NUM_RAMB_36_DC}
}

proc update_MODELPARAM_VALUE.DATAWIDTH_36K { MODELPARAM_VALUE.DATAWIDTH_36K PARAM_VALUE.DATAWIDTH_36K } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATAWIDTH_36K}] ${MODELPARAM_VALUE.DATAWIDTH_36K}
}

proc update_MODELPARAM_VALUE.NUM_RAMB_18_DC { MODELPARAM_VALUE.NUM_RAMB_18_DC PARAM_VALUE.NUM_RAMB_18_DC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_RAMB_18_DC}] ${MODELPARAM_VALUE.NUM_RAMB_18_DC}
}

proc update_MODELPARAM_VALUE.DATAWIDTH_18K { MODELPARAM_VALUE.DATAWIDTH_18K PARAM_VALUE.DATAWIDTH_18K } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATAWIDTH_18K}] ${MODELPARAM_VALUE.DATAWIDTH_18K}
}

proc update_MODELPARAM_VALUE.nbtap { MODELPARAM_VALUE.nbtap PARAM_VALUE.nbtap } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.nbtap}] ${MODELPARAM_VALUE.nbtap}
}

proc update_MODELPARAM_VALUE.dsize { MODELPARAM_VALUE.dsize PARAM_VALUE.dsize } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.dsize}] ${MODELPARAM_VALUE.dsize}
}

proc update_MODELPARAM_VALUE.Numbr_of_DSP { MODELPARAM_VALUE.Numbr_of_DSP PARAM_VALUE.Numbr_of_DSP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Numbr_of_DSP}] ${MODELPARAM_VALUE.Numbr_of_DSP}
}

