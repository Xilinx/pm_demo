///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
// SPDX-License-Identifier: MIT
///////////////////////////////////////////////////////////////////////////////

module power (
     input rst_out0,
     input rst_out1,
     input system_clk
);

parameter NUM_LOGIC_BLOCKS 		= 1200; 	// * 30 logic blocks in OOC run

parameter NUM_RAMB_36_DC 		= 400; 	//
parameter DATAWIDTH_36K     		= 36;

parameter NUM_RAMB_18_DC 		= 300; 	//
parameter DATAWIDTH_18K     		= 18;

parameter nbtap = 4;
parameter dsize = 16;
parameter Numbr_of_DSP = 300;


	logic_top  #(.NUM_LOGIC_BLOCKS(NUM_LOGIC_BLOCKS)) ulogic
		(
		.clk(system_clk),
		.rst(rst_out)
		);

	block_ram_daisy_chain  #(.NUM_RAMB(NUM_RAMB_18_DC), .SIM(), .DATAWIDTH(DATAWIDTH_18K)) block_ram_daisy_chain_18k
		(
		.clk(system_clk),
		.irst(rst_out)
		);

	block_ram_daisy_chain  #(.NUM_RAMB(NUM_RAMB_36_DC), .SIM(), .DATAWIDTH(DATAWIDTH_36K)) block_ram_daisy_chain_36k
		(
		.clk(system_clk),
		.irst(rst_out)
		);

    generate_sfir  #(.nbtap(nbtap),.dsize(dsize),.N(Numbr_of_DSP)) udsp (
      .clk(system_clk),
      .rst(rst_out)
  );

endmodule