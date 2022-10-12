`timescale 1ns / 1ps

module logic_top # (
    parameter NUM_LOGIC_BLOCKS 	= 10
    )
    (
	input clk,
	input rst
    );

	wire clk, clk_se, dclk, o_mask;

	wire [6:0] toggle_rate_vio;
	reg [6:0] toggle_rate;
	
	reg rst_out;
	wire vio_rst;
	wire reset;
	
	wire [NUM_LOGIC_BLOCKS-1:0] mask_out;
	wire [NUM_LOGIC_BLOCKS-1:0] cc_out;
	reg  [NUM_LOGIC_BLOCKS-1:0] rst_reg;
	(* DONT_TOUCH="TRUE" *)	reg  [NUM_LOGIC_BLOCKS-1:0] rst_logic_r1;
	(* DONT_TOUCH="TRUE" *)	reg  [NUM_LOGIC_BLOCKS-1:0] rst_logic_r2;
	reg  [NUM_LOGIC_BLOCKS-1:0] rst_logic;
	
	wire cc_out_reduced;
	wire mask_out_reduced;
	    
	     
	assign cc_out_reduced = ^{cc_out};
	assign mask_out_reduced = ^{mask_out};
	
	vio_top_logic uvio_top_logic (
	  .clk(clk),                // input wire clk
	  .probe_in0(cc_out_reduced),    // Input to stop optimization
	  .probe_in1(mask_out_reduced),    // Input to stop optimization
	  .probe_out0(toggle_rate_vio),  // Toggle rate - Decimal % vale
	  .probe_out1(vio_rst)  // enables/disable toggling of logic 
 	);
	
	assign reset = rst | vio_rst;

	always @ (posedge clk)
		rst_reg	<= {rst_reg[NUM_LOGIC_BLOCKS-2:0], reset};

	 
	always @ (posedge clk)
	    toggle_rate <= toggle_rate_vio;
	      
	   genvar num_logic;
	    generate
	       for (num_logic=0; num_logic < NUM_LOGIC_BLOCKS; num_logic=num_logic+1) 
	       begin: logic_gen
		   logic  ulogic1 (
		       .clk(clk),
		       .rst(rst_reg[num_logic]), 
		       .cc_out(cc_out[num_logic]), 
		       .o_mask_out(mask_out[num_logic]), 
		       .toggle_rate_vio(toggle_rate) 
		       );
	       end
	    endgenerate

endmodule