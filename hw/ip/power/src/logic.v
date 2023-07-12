///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
// SPDX-License-Identifier: MIT
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module logic
    (
	input          clk,
	input          rst,
	output         cc_out,
	output         o_mask_out,
	input [6:0]    toggle_rate_vio
    );

parameter NUM_BASE_LOGIC_BLOCKS 	= 30;  //50

wire                           cascade_in;
wire [NUM_BASE_LOGIC_BLOCKS:0] cascade_out;

reg                            mask_in;
wire [NUM_BASE_LOGIC_BLOCKS:0] mask_out;
reg	 [6:0]				       mask_count;
reg	 [6:0]				       toggle_rate;
reg	 [6:0]				       toggle_rate_lut;
reg	 [6:0]				       toggle_rate_ff;
reg                            disable_logic;

assign cc_out = cascade_out[NUM_BASE_LOGIC_BLOCKS];
assign o_mask_out = mask_out[NUM_BASE_LOGIC_BLOCKS];


//FF toggle rate counter
always @ (posedge clk)
	begin
	if (rst || disable_logic)
		mask_count 	<= 1;
	else
		begin
		if (mask_count == 7'd100)
			mask_count 	<= 1;
		else
			mask_count	<= mask_count + 1;
		end
	end

//Mask enable rate
always @ (posedge clk)
    begin
    if (rst || disable_logic)
        mask_in 	<= 1;
    else
        begin
        if (mask_count <= toggle_rate)
            mask_in 	<= 0;
        else
            mask_in 	<= 1;
        end
    end

//Mask enable rate
always @ (posedge clk)
    begin
    if (toggle_rate_vio == 7'h0)
        disable_logic 	<= 1;
    else
        disable_logic 	<= 0;
    if (toggle_rate_vio >= 7'd100)
        toggle_rate 	<= 7'd100;
    else
        toggle_rate 	<= toggle_rate_vio;
    end


// Basic_Block
//
(* DONT_TOUCH="TRUE" *)	basic_block ubasic_block (
		.clk(clk),
		.rst(rst),
		.mask_in(mask_in),
		.mask_out(mask_out[0]),
		.cascade_in(rst),
		.cascade_out(cascade_out[0])
	);

   genvar cnt;
   generate
      for (cnt=1; cnt < NUM_BASE_LOGIC_BLOCKS+1; cnt=cnt+1)
      begin: logic_gen
(* DONT_TOUCH="TRUE" *)	basic_block ubasic_block (
		.clk(clk),
		.rst(rst),
		.mask_in(mask_out[cnt-1]),
		.mask_out(mask_out[cnt]),
		.cascade_in(cascade_out[cnt-1]),
		.cascade_out(cascade_out[cnt])
	);
      end
   endgenerate

always @ (posedge clk)
    begin
    toggle_rate_lut = toggle_rate;
    toggle_rate_ff = toggle_rate * 7 / 8;
    end

endmodule


module basic_block (
	input 	wire		clk,
	input 	wire		rst,
	input	wire	mask_in,
(* DONT_TOUCH="TRUE" *)	output	reg	mask_out,
    input 	wire		cascade_in,
(* DONT_TOUCH="TRUE" *)	output	reg		cascade_out
	);

(* DONT_TOUCH="TRUE" *) reg	[5:0]	data;
(* DONT_TOUCH="TRUE" *) reg	[5:0]	data1;
(* DONT_TOUCH="TRUE" *) reg	[5:0]	data2;

(* DONT_TOUCH="TRUE" *) wire 		reduction_wire;

wire 		toggle_wire;

//reduce LUTs (* DONT_TOUCH="TRUE" *) wire 	[5:0]	mask_in_wire;
 wire 	[5:0]	mask_in_wire;

assign mask_in_wire = {mask_in, mask_in, mask_in, mask_in, mask_in, mask_in};

always @ (posedge clk)
	mask_out <= mask_in;

always @ (posedge clk)
	begin
	if (rst)
	   begin
	   data <= 0;
	   data1 <= 0;
	   data2 <= 0;
	   end
	else
	   begin
	   data <= (mask_in_wire | ~data);
	   data1 <= (mask_in_wire | ~data);
	   data2 <= (mask_in_wire | ~data);
	   end
	end

assign reduction_wire = (((~&(data)) & (~&(data1)) & (~&(data2))) | cascade_in);

assign toggle_wire = reduction_wire;

always @ (posedge clk)
	cascade_out <= toggle_wire;

endmodule