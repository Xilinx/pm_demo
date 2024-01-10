###############################################################################
# Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

proc create_vck190_power1_slot0 { parentCell nameHier } {

    set parentObj [get_bd_cells $parentCell]

    set oldCurInst [current_bd_instance .]

    current_bd_instance $parentObj

    if {$nameHier ne "" } {

        set hier_obj [create_bd_cell -type hier $nameHier]

        current_bd_instance $hier_obj
    }
    set clk_p [ create_bd_port -dir I clk_p ]
    set clk_n [ create_bd_port -dir I clk_n ]

    set CLK_WIZ_EVE_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard CLK_WIZ_EVE_1 ]


    set_property -dict [ list \
        CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {450,100.0,100.0,100.0,100.0,100.0,100.0} \
        CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
        CONFIG.USE_LOCKED {true} \
    ] $CLK_WIZ_EVE_1

    set UTIL_DS_BUF_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf UTIL_DS_BUF_1 ] 
    
    set_property -dict [ list \
            CONFIG.C_BUF_TYPE {BUFG} \
    ] $UTIL_DS_BUF_1 

    set UTIL_DS_BUF_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf UTIL_DS_BUF_0 ]

    set POWER_0 [ create_bd_cell -type ip -vlnv user.org:user:power POWER_0 ]
    #startgroup
    #set_property -dict [list \
    #  CONFIG.NUM_LOGIC_BLOCKS {120} \
    #  CONFIG.NUM_RAMB_18_DC {30} \
    #  CONFIG.NUM_RAMB_36_DC {40} \
    #  CONFIG.Numbr_of_DSP {30} \
    #] [get_bd_cells POWER_0]
    #endgroup



    connect_bd_net -net CLK_WIZ_EVE_1_locked_POWER_0_rst_out1 [get_bd_pins CLK_WIZ_EVE_1/locked] [get_bd_pins POWER_0/rst_out0]
    connect_bd_net -net CLK_WIZ_EVE_1_clk_out1_POWER_0_system_clk [get_bd_pins CLK_WIZ_EVE_1/clk_out1] [get_bd_pins POWER_0/system_clk]
    connect_bd_net -net slot0_PORT_0_clk_p_UTIL_DS_BUF_0_IBUF_DS_P [get_bd_pins clk_p] [get_bd_pins UTIL_DS_BUF_0/IBUF_DS_P]
    connect_bd_net -net slot0_PORT_1_clk_n_UTIL_DS_BUF_0_IBUF_DS_N [get_bd_pins clk_n] [get_bd_pins UTIL_DS_BUF_0/IBUF_DS_N]
    connect_bd_net -net UTIL_DS_BUF_0_IBUF_OUT_UTIL_DS_BUF_1_BUFG_I [get_bd_pins UTIL_DS_BUF_0/IBUF_OUT] [get_bd_pins UTIL_DS_BUF_1/BUFG_I]
    connect_bd_net -net UTIL_DS_BUFG_O_CLK_WIZ_EVE_0_clk_in1 [get_bd_pins UTIL_DS_BUF_1/BUFG_O] [get_bd_pins CLK_WIZ_EVE_1/clk_in1]
    

    current_bd_instance $oldCurInst
}


proc create_vck190_power1 { parentCell nameHier } {

    set parentObj [get_bd_cells $parentCell]

    set oldCurInst [current_bd_instance .]

    current_bd_instance $parentObj
    if {$nameHier ne "" } {

        set hier_obj [create_bd_cell -type hier $nameHier]

        current_bd_instance $hier_obj
    }

    set curdesign [current_bd_design]
    create_bd_design slot0
    create_vck190_power1_slot0 "" ""
    assign_bd_address
    save_bd_design
    validate_bd_design
    #set new_pd [create_partition_def -name slot0 -module slot0]
    #create_reconfig_module -name slot0 -partition_def $new_pd -define_from slot0
    current_bd_design $curdesign
    set slot0 [create_bd_cell -type container -reference slot0 slot0 ]
    set_property -dict [ list \
    CONFIG.ACTIVE_SIM_BD {slot0.bd} \
    CONFIG.ACTIVE_SYNTH_BD {slot0.bd} \
    CONFIG.ENABLE_DFX {true} \
    CONFIG.LIST_SIM_BD {slot0.bd} \
    CONFIG.LIST_SYNTH_BD {slot0.bd} \
    CONFIG.LOCK_PROPAGATE {true} \
    ] $slot0



    set CH0_DDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 CH0_DDR4_0_0 ]
    set clk_p [ create_bd_port -dir I clk_p ]
    set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
    set_property -dict [ list \
        CONFIG.FREQ_HZ {200000000.0} \
    ] $sys_clk0_0
    set clk_n [ create_bd_port -dir I clk_n ]

    set ::PS_INST CIPS_0
    set CIPS_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips CIPS_0 ]


    set_property -dict [ list \
    CONFIG.PS_PMC_CONFIG { \
        PMC_CRP_CFU_REF_CTRL_DIVISOR0 4 \
        PMC_CRP_CFU_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_DFT_OSC_REF_CTRL_DIVISOR0 3 \
        PMC_CRP_DFT_OSC_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_HSM0_REF_CTRL_DIVISOR0 36 \
        PMC_CRP_HSM0_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_HSM1_REF_CTRL_DIVISOR0 9 \
        PMC_CRP_HSM1_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_I2C_REF_CTRL_DIVISOR0 12 \
        PMC_CRP_I2C_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_LSBUS_REF_CTRL_DIVISOR0 12 \
        PMC_CRP_LSBUS_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_NOC_REF_CTRL_DIVISOR0 1 \
        PMC_CRP_NOC_REF_CTRL_SRCSEL NPLL \
        PMC_CRP_NPI_REF_CTRL_DIVISOR0 4 \
        PMC_CRP_NPI_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_NPLL_CTRL_CLKOUTDIV 4 \
        PMC_CRP_NPLL_CTRL_FBDIV 115 \
        PMC_CRP_NPLL_CTRL_SRCSEL REF_CLK \
        PMC_CRP_NPLL_TO_XPD_CTRL_DIVISOR0 1 \
        PMC_CRP_OSPI_REF_CTRL_DIVISOR0 6 \
        PMC_CRP_OSPI_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_PL0_REF_CTRL_DIVISOR0 5 \
        PMC_CRP_PL0_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_PL1_REF_CTRL_DIVISOR0 5 \
        PMC_CRP_PL1_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_PL2_REF_CTRL_DIVISOR0 5 \
        PMC_CRP_PL2_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_PL3_REF_CTRL_DIVISOR0 5 \
        PMC_CRP_PL3_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_PPLL_CTRL_CLKOUTDIV 2 \
        PMC_CRP_PPLL_CTRL_FBDIV 72 \
        PMC_CRP_PPLL_CTRL_SRCSEL REF_CLK \
        PMC_CRP_PPLL_TO_XPD_CTRL_DIVISOR0 2 \
        PMC_CRP_QSPI_REF_CTRL_DIVISOR0 4 \
        PMC_CRP_QSPI_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_SDIO0_REF_CTRL_DIVISOR0 6 \
        PMC_CRP_SDIO0_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_SDIO1_REF_CTRL_DIVISOR0 6 \
        PMC_CRP_SDIO1_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_SD_DLL_REF_CTRL_DIVISOR0 1 \
        PMC_CRP_SD_DLL_REF_CTRL_SRCSEL PPLL \
        PMC_CRP_SYSMON_REF_CTRL_SRCSEL NPI_REF_CLK \
        PMC_CRP_TEST_PATTERN_REF_CTRL_DIVISOR0 6 \
        PMC_CRP_TEST_PATTERN_REF_CTRL_SRCSEL PPLL \
        PMC_GPIO0_MIO_PERIPHERAL { \
            {ENABLE 1} \
        } \
        PMC_GPIO1_MIO_PERIPHERAL { \
            {ENABLE 1} \
        } \
        PMC_HSM0_CLOCK_ENABLE 1 \
        PMC_HSM1_CLOCK_ENABLE 1 \
        PMC_I2CPMC_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PMC_MIO 46 .. 47}} \
        } \
        PMC_MIO37 { \
            {DIRECTION out} \
            {OUTPUT_DATA high} \
            {PULL pulldown} \
            {USAGE GPIO} \
        } \
        PMC_MIO48 { \
            {DIRECTION out} \
            {PULL pullup} \
            {USAGE GPIO} \
        } \
        PMC_MIO49 { \
            {DIRECTION out} \
            {PULL pullup} \
            {USAGE GPIO} \
        } \
        PMC_QSPI_FBCLK { \
            {ENABLE 1} \
        } \
        PMC_QSPI_PERIPHERAL_DATA_MODE x4 \
        PMC_QSPI_PERIPHERAL_ENABLE 1 \
        PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
        PMC_SD1 { \
            {CD_ENABLE 1} \
            {POW_ENABLE 1} \
        } \
        PMC_SD1_DATA_TRANSFER_MODE 8Bit \
        PMC_SD1_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PMC_MIO 26 .. 36}} \
        } \
        PMC_SD1_SLOT_TYPE {SD 3.0} \
        PMC_USE_PMC_NOC_AXI0 1 \
        PSPMC_MANUAL_CLK_ENABLE 1 \
        PS_CAN1_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PMC_MIO 40 .. 41}} \
        } \
        PS_CRF_ACPU_CTRL_DIVISOR0 1 \
        PS_CRF_ACPU_CTRL_SRCSEL APLL \
        PS_CRF_APLL_CTRL_CLKOUTDIV 4 \
        PS_CRF_APLL_CTRL_FBDIV 120 \
        PS_CRF_APLL_CTRL_SRCSEL REF_CLK \
        PS_CRF_APLL_TO_XPD_CTRL_DIVISOR0 2 \
        PS_CRF_DBG_FPD_CTRL_DIVISOR0 3 \
        PS_CRF_DBG_FPD_CTRL_SRCSEL APLL \
        PS_CRF_DBG_TRACE_CTRL_DIVISOR0 3 \
        PS_CRF_DBG_TRACE_CTRL_SRCSEL APLL \
        PS_CRF_FPD_LSBUS_CTRL_DIVISOR0 6 \
        PS_CRF_FPD_LSBUS_CTRL_SRCSEL PPLL \
        PS_CRF_FPD_TOP_SWITCH_CTRL_DIVISOR0 2 \
        PS_CRF_FPD_TOP_SWITCH_CTRL_SRCSEL APLL \
        PS_CRL_CAN0_REF_CTRL_DIVISOR0 6 \
        PS_CRL_CAN0_REF_CTRL_SRCSEL NPLL \
        PS_CRL_CAN1_REF_CTRL_DIVISOR0 6 \
        PS_CRL_CAN1_REF_CTRL_SRCSEL NPLL \
        PS_CRL_CPM_TOPSW_REF_CTRL_DIVISOR0 2 \
        PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL NPLL \
        PS_CRL_CPU_R5_CTRL_DIVISOR0 2 \
        PS_CRL_CPU_R5_CTRL_SRCSEL RPLL \
        PS_CRL_DBG_LPD_CTRL_DIVISOR0 3 \
        PS_CRL_DBG_LPD_CTRL_SRCSEL PPLL \
        PS_CRL_DBG_TSTMP_CTRL_DIVISOR0 2 \
        PS_CRL_DBG_TSTMP_CTRL_SRCSEL PPLL \
        PS_CRL_GEM0_REF_CTRL_DIVISOR0 6 \
        PS_CRL_GEM0_REF_CTRL_SRCSEL RPLL \
        PS_CRL_GEM1_REF_CTRL_DIVISOR0 6 \
        PS_CRL_GEM1_REF_CTRL_SRCSEL RPLL \
        PS_CRL_GEM_TSU_REF_CTRL_DIVISOR0 3 \
        PS_CRL_GEM_TSU_REF_CTRL_SRCSEL RPLL \
        PS_CRL_I2C0_REF_CTRL_DIVISOR0 6 \
        PS_CRL_I2C0_REF_CTRL_SRCSEL PPLL \
        PS_CRL_I2C1_REF_CTRL_DIVISOR0 6 \
        PS_CRL_I2C1_REF_CTRL_SRCSEL PPLL \
        PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 3 \
        PS_CRL_IOU_SWITCH_CTRL_SRCSEL RPLL \
        PS_CRL_LPD_LSBUS_CTRL_DIVISOR0 6 \
        PS_CRL_LPD_LSBUS_CTRL_SRCSEL PPLL \
        PS_CRL_LPD_TOP_SWITCH_CTRL_DIVISOR0 2 \
        PS_CRL_LPD_TOP_SWITCH_CTRL_SRCSEL RPLL \
        PS_CRL_PSM_REF_CTRL_DIVISOR0 2 \
        PS_CRL_PSM_REF_CTRL_SRCSEL PPLL \
        PS_CRL_RPLL_CTRL_CLKOUTDIV 4 \
        PS_CRL_RPLL_CTRL_FBDIV 90 \
        PS_CRL_RPLL_CTRL_SRCSEL REF_CLK \
        PS_CRL_RPLL_TO_XPD_CTRL_DIVISOR0 3 \
        PS_CRL_SPI0_REF_CTRL_DIVISOR0 3 \
        PS_CRL_SPI0_REF_CTRL_SRCSEL PPLL \
        PS_CRL_SPI1_REF_CTRL_DIVISOR0 3 \
        PS_CRL_SPI1_REF_CTRL_SRCSEL PPLL \
        PS_CRL_TIMESTAMP_REF_CTRL_DIVISOR0 6 \
        PS_CRL_TIMESTAMP_REF_CTRL_SRCSEL PPLL \
        PS_CRL_UART0_REF_CTRL_DIVISOR0 6 \
        PS_CRL_UART0_REF_CTRL_SRCSEL PPLL \
        PS_CRL_UART1_REF_CTRL_DIVISOR0 6 \
        PS_CRL_UART1_REF_CTRL_SRCSEL PPLL \
        PS_CRL_USB0_BUS_REF_CTRL_DIVISOR0 30 \
        PS_CRL_USB0_BUS_REF_CTRL_SRCSEL PPLL \
        PS_CRL_USB3_DUAL_REF_CTRL_DIVISOR0 60 \
        PS_CRL_USB3_DUAL_REF_CTRL_SRCSEL PPLL \
        PS_ENET0_MDIO { \
            {ENABLE 1} \
            {IO {PS_MIO 24 .. 25}} \
        } \
        PS_ENET0_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PS_MIO 0 .. 11}} \
        } \
        PS_ENET1_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PS_MIO 12 .. 23}} \
        } \
        PS_GEM0_ROUTE_THROUGH_FPD 1 \
        PS_GEM1_ROUTE_THROUGH_FPD 1 \
        PS_GEN_IPI0_ENABLE 1 \
        PS_GEN_IPI0_MASTER A72 \
        PS_GEN_IPI1_ENABLE 1 \
        PS_GEN_IPI1_MASTER R5_0 \
        PS_GEN_IPI2_ENABLE 1 \
        PS_GEN_IPI2_MASTER R5_1 \
        PS_GEN_IPI3_ENABLE 1 \
        PS_GEN_IPI3_MASTER A72 \
        PS_GEN_IPI4_ENABLE 1 \
        PS_GEN_IPI4_MASTER A72 \
        PS_GEN_IPI5_ENABLE 1 \
        PS_GEN_IPI5_MASTER A72 \
        PS_GEN_IPI6_ENABLE 1 \
        PS_GEN_IPI6_MASTER A72 \
        PS_GEN_IPI_PMCNOBUF_ENABLE 1 \
        PS_GEN_IPI_PMC_ENABLE 1 \
        PS_GEN_IPI_PSM_ENABLE 1 \
        PS_GPIO2_MIO_PERIPHERAL { \
            {ENABLE 1} \
        } \
        PS_I2C1_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PMC_MIO 44 .. 45}} \
        } \
        PS_LPDMA0_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA1_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA2_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA3_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA4_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA5_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA6_ROUTE_THROUGH_FPD 1 \
        PS_LPDMA7_ROUTE_THROUGH_FPD 1 \
        PS_MIO19 { \
            {PULL disable} \
        } \
        PS_MIO21 { \
            {PULL disable} \
        } \
        PS_MIO7 { \
            {PULL disable} \
        } \
        PS_MIO9 { \
            {PULL disable} \
        } \
        PS_NUM_FABRIC_RESETS 4 \
        PS_TTC0_PERIPHERAL_ENABLE 1 \
        PS_TTC1_PERIPHERAL_ENABLE 1 \
        PS_TTC2_PERIPHERAL_ENABLE 1 \
        PS_TTC3_PERIPHERAL_ENABLE 1 \
        PS_UART0_BAUD_RATE 115200 \
        PS_UART0_PERIPHERAL { \
            {ENABLE 1} \
            {IO {PMC_MIO 42 .. 43}} \
        } \
        PS_USB3_PERIPHERAL { \
            {ENABLE 1} \
        } \
        PS_USB_ROUTE_THROUGH_FPD 1 \
        PS_USE_FPD_AXI_NOC0 1 \
        PS_USE_FPD_AXI_NOC1 1 \
        PS_USE_FPD_CCI_NOC  1 \
        PS_USE_FPD_CCI_NOC0 1 \
        PS_USE_FPD_CCI_NOC1 1 \
        PS_USE_FPD_CCI_NOC2 1 \
        PS_USE_FPD_CCI_NOC3 1 \
        PS_USE_NOC_LPD_AXI0 1 \
        PS_USE_PMCPL_CLK0 1 \
        PS_WWDT0_CLK { \
            {ENABLE 1} \
            {IO {APB}} \
        } \
        PS_WWDT0_PERIPHERAL { \
            {ENABLE 1} \
            {IO {EMIO}} \
        } \
        } \
    ] $CIPS_0


    set ::NOC_INST_0 NOC_0
    set NOC_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.0 NOC_0 ]


    set_property -dict [ list \
        CONFIG.NUM_CLKS {8} \
        CONFIG.NUM_MI {0} \
        CONFIG.NUM_NMI {0} \
        CONFIG.NUM_NSI {0} \
        CONFIG.NUM_SI {8} \
    ] $NOC_0

    set_property -dict [ list \
        CONFIG.CONTROLLERTYPE {DDR4_SDRAM} \
        CONFIG.MC_BA_WIDTH {2} \
        CONFIG.MC_BG_WIDTH {2} \
        CONFIG.MC_CHAN_REGION0 {DDR_LOW0} \
        CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
        CONFIG.MC_COMPONENT_WIDTH {x8} \
        CONFIG.MC_DATAWIDTH {64} \
        CONFIG.MC_INPUTCLK0_PERIOD {5000} \
        CONFIG.MC_INTERLEAVE_SIZE {128} \
        CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} \
        CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
        CONFIG.MC_MEMORY_TIMEPERIOD0 {625} \
        CONFIG.MC_NO_CHANNELS {Single} \
        CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_COLUMN_BANK} \
        CONFIG.MC_RANK {1} \
        CONFIG.MC_ROWADDRESSWIDTH {16} \
        CONFIG.NUM_MC {1} \
        CONFIG.NUM_MCP {4} \
    ] [get_bd_cells NOC_0]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_rpu} \
        CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S06_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_pmc} \
        CONFIG.CONNECTIONS {MC_3 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S07_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_cci} \
        CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S04_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_cci} \
        CONFIG.CONNECTIONS {MC_3 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S05_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_nci} \
        CONFIG.CONNECTIONS {MC_1 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S01_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_cci} \
        CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S02_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_cci} \
        CONFIG.CONNECTIONS {MC_1 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S03_AXI]

    set_property -dict [ list \
        CONFIG.CATEGORY {ps_nci} \
        CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5}}} \
    ] [get_bd_intf_pins NOC_0/S00_AXI]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
    ] [get_bd_pins NOC_0/aclk1]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
    ] [get_bd_pins NOC_0/aclk7]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
    ] [get_bd_pins NOC_0/aclk0]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
    ] [get_bd_pins NOC_0/aclk3]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
    ] [get_bd_pins NOC_0/aclk6]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
    ] [get_bd_pins NOC_0/aclk4]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
    ] [get_bd_pins NOC_0/aclk2]

    set_property -dict [ list \
        CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
    ] [get_bd_pins NOC_0/aclk5]

    connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_0_NOC_0_S02_AXI [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_0] [get_bd_intf_pins NOC_0/S02_AXI]
    connect_bd_net -net CIPS_0_fpd_cci_noc_axi1_clk_NOC_0_aclk3 [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins NOC_0/aclk3]
    connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_3_NOC_0_S05_AXI [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_3] [get_bd_intf_pins NOC_0/S05_AXI]
    connect_bd_net -net CIPS_0_fpd_axi_noc_axi0_clk_NOC_0_aclk0 [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins NOC_0/aclk0]
    connect_bd_net -net CIPS_0_fpd_cci_noc_axi2_clk_NOC_0_aclk4 [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins NOC_0/aclk4]
    connect_bd_intf_net -intf_net CIPS_0_LPD_AXI_NOC_0_NOC_0_S06_AXI [get_bd_intf_pins CIPS_0/LPD_AXI_NOC_0] [get_bd_intf_pins NOC_0/S06_AXI]
    connect_bd_intf_net -intf_net CIPS_0_FPD_AXI_NOC_0_NOC_0_S00_AXI [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_0] [get_bd_intf_pins NOC_0/S00_AXI]
    connect_bd_net -net CIPS_0_fpd_axi_noc_axi1_clk_NOC_0_aclk1 [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins NOC_0/aclk1]
    connect_bd_intf_net -intf_net CIPS_0_FPD_AXI_NOC_1_NOC_0_S01_AXI [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_1] [get_bd_intf_pins NOC_0/S01_AXI]
    connect_bd_net -net CIPS_0_fpd_cci_noc_axi0_clk_NOC_0_aclk2 [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins NOC_0/aclk2]
    connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_2_NOC_0_S04_AXI [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_2] [get_bd_intf_pins NOC_0/S04_AXI]
    connect_bd_net -net CIPS_0_pmc_axi_noc_axi0_clk_NOC_0_aclk7 [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins NOC_0/aclk7]
    connect_bd_net -net CIPS_0_fpd_cci_noc_axi3_clk_NOC_0_aclk5 [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins NOC_0/aclk5]
    connect_bd_net -net CIPS_0_lpd_axi_noc_clk_NOC_0_aclk6 [get_bd_pins CIPS_0/lpd_axi_noc_clk] [get_bd_pins NOC_0/aclk6]
    connect_bd_intf_net -intf_net CIPS_0_PMC_NOC_AXI_0_NOC_0_S07_AXI [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_0] [get_bd_intf_pins NOC_0/S07_AXI]
    connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_1_NOC_0_S03_AXI [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_1] [get_bd_intf_pins NOC_0/S03_AXI]
    connect_bd_intf_net -intf_net vck190_power1_INTF_PORT_1_CH0_DDR4_0_0_NOC_0_CH0_DDR4_0 [get_bd_intf_ports CH0_DDR4_0_0] [get_bd_intf_pins NOC_0/CH0_DDR4_0]
    connect_bd_net -net vck190_power1_PORT_0_clk_p_slot0_PORT_0_clk_p [get_bd_ports clk_p] [get_bd_pins slot0/clk_p]
    connect_bd_intf_net -intf_net vck190_power1_INTF_PORT_0_sys_clk0_0_NOC_0_sys_clk0 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins NOC_0/sys_clk0]
    connect_bd_net -net vck190_power1_PORT_1_clk_n_slot0_PORT_1_clk_n [get_bd_ports clk_n] [get_bd_pins slot0/clk_n]

    current_bd_instance $oldCurInst
}

create_vck190_power1 "" ""


proc create_main_reconfig_partitions { } {

}
