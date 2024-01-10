///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
// SPDX-License-Identifier: MIT
///////////////////////////////////////////////////////////////////////////////

//`define SIM

module block_ram_daisy_chain # (
    parameter NUM_RAMB = 2,
    parameter SIM = "FALSE",
    parameter DATAWIDTH = "36"
    )
    (
	input clk,
	input irst,
	input dclk
    );


reg 	[DATAWIDTH-1:0]			rd_data;
wire 	[((NUM_RAMB+1)*DATAWIDTH)-1:0]	wr_data;
wire 	[DATAWIDTH-1:0]			rd_data_init;
`ifdef SIM
reg 	[2:0] 				wr_addr, rd_addr;
`else
reg 	[9:0] 				wr_addr, rd_addr;
`endif
reg 	[1:0] 				en_rd_cnt;

reg					rst;

wire 					ram_en;
wire 					ram_wr_en;
wire 					ram_rd_en;
wire                			en_b;
wire    [((NUM_RAMB+1)*10)-1:0]   	rd_addr_dc;
wire	[NUM_RAMB:0]			ram_en_dc;
wire	[NUM_RAMB:0]			ram_rd_en_dc;
wire	[NUM_RAMB:0]			ram_wr_en_dc;
reg	[6:0]				mask_count;
reg	[6:0]				           toggle_rate;
wire	[6:0]				           toggle_rate_vio;
reg                             disable_logic;

always @ (posedge clk)
	rst <= irst;

// Address pointers

always @ (posedge clk)
	begin
	if (rst)
		rd_addr <= 0;
	else
		begin
		if (ram_rd_en && ram_en)
			rd_addr <= rd_addr + 1;
		else
			rd_addr <= rd_addr;
		end
	end

	//FF toggle rate counter
    always @ (posedge clk)
    	begin
    	if (rst | en_b | disable_logic)
    		mask_count 	<= 1;
    	else
    		begin
    		if (mask_count == 7'd100)
    			mask_count 	<= 1;
    		else
    			mask_count	<= mask_count + 1;
    		end
    	end
// Data generation

	always @ (posedge clk)
    	begin
    	if (rst || en_b || !ram_en || !ram_rd_en || disable_logic)
    		rd_data <= rd_data_init;
    	else
    		begin
    		if (mask_count <= toggle_rate)
    			rd_data <= ~rd_data;
    		else
    			rd_data <= rd_data_init;
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
	ramb_sp_daisy_chain #(.DATAWIDTH(DATAWIDTH)) uramb_sp_daisy_chain (
		.clk(clk),
		.rst(rst),
		.ram_en(ram_en),
		.ram_rd_en(ram_rd_en),
		.ram_wr_en(ram_wr_en),
		.rd_addr(rd_addr),
		.wr_addr(rd_addr),
		.rd_data(rd_data),
		.wr_data(wr_data[DATAWIDTH-1:0]),
		.rd_addr_dc(rd_addr_dc[9:0]),
		.ram_en_dc(ram_en_dc[0]),
        	.ram_rd_en_dc(ram_rd_en_dc[0]),
        	.ram_wr_en_dc(ram_wr_en_dc[0])
		);

// Block Ram 36k
   genvar cnt;
   generate
      for (cnt=1; cnt < NUM_RAMB+1; cnt=cnt+1)
      begin: ram_gen
	ramb_sp_daisy_chain #(.DATAWIDTH(DATAWIDTH)) uramb_sp_daisy_chain (
		.clk(clk),
		.rst(rst),
		.ram_en(ram_en_dc[cnt-1]),
		.ram_rd_en(ram_rd_en_dc[cnt-1]),
		.ram_wr_en(ram_wr_en_dc[cnt-1]),
		.rd_addr(rd_addr_dc[cnt*10-1:(cnt-1)*10]),
		.wr_addr(rd_addr_dc[cnt*10-1:(cnt-1)*10]),
		.rd_data(wr_data[cnt*DATAWIDTH-1:(cnt-1)*DATAWIDTH]),
		.wr_data(wr_data[(cnt+1)*DATAWIDTH-1:cnt*DATAWIDTH]),
		.rd_addr_dc(rd_addr_dc[((cnt+1)*10)-1:cnt*10]),
		.ram_en_dc(ram_en_dc[cnt]),
        	.ram_rd_en_dc(ram_rd_en_dc[cnt]),
        	.ram_wr_en_dc(ram_wr_en_dc[cnt])
	);
      end
   endgenerate



// VIO for control

wire [255:0] SYNC_IN; // IN BUS [255:0]
wire [255:0] SYNC_OUT; // OUT BUS [255:0]


generate
if (SIM == "TRUE") begin : sim
bram_dc_tb u_vio_bram_dc (
    .CLK(clk), // IN
    .rst(rst),
    .SYNC_IN(SYNC_IN), // IN BUS [255:0]
    .SYNC_OUT(SYNC_OUT) // OUT BUS [255:0]
);
end
else if (SIM == "FALSE") begin : impl
vio_bram u_vio_bram_dc (
    .clk(clk), // IN
    .probe_in0(wr_data[(NUM_RAMB+1)*DATAWIDTH-1:(NUM_RAMB)*DATAWIDTH]),    // input wire [35 : 0] probe_in0
    .probe_in1(toggle_rate),    // input wire [6 : 0] probe_in1
    .probe_out0(ram_en),  // output wire [0 : 0] probe_out0
    .probe_out1(ram_wr_en),  // output wire [0 : 0] probe_out1
    .probe_out2(ram_rd_en),  // output wire [0 : 0] probe_out2
    .probe_out3(en_b),  // output wire [0 : 0] probe_out3
    .probe_out4(rd_data_init),  // output wire [35 : 0] probe_out4
    .probe_out5(toggle_rate_vio)  // output wire [6 : 0] probe_out5
);
end
endgenerate

endmodule


module ramb_sp_daisy_chain # (
    	parameter DATAWIDTH = "36"
    	)
    	(
	input 	wire			clk,
	input 	wire			rst,
	input 	wire			ram_en,
	input 	wire			ram_rd_en,
	input 	wire			ram_wr_en,
	input	wire	[9:0]		rd_addr,
	input	wire	[9:0]		wr_addr,
	input 	wire	[DATAWIDTH-1:0]	rd_data,
	output 	reg	    [DATAWIDTH-1:0]	wr_data,
	output 	reg     [9:0]   	rd_addr_dc,
    	output 	reg			ram_en_dc,
    	output 	reg			ram_rd_en_dc,
    	output 	reg			ram_wr_en_dc

	);

reg	[DATAWIDTH-1:0]	wr_data_int;
reg 	[DATAWIDTH-1:0]	memory [1023:0];

always @ (posedge clk)
    begin
    rd_addr_dc  <= rd_addr;
    ram_en_dc <=   ram_en;
    ram_rd_en_dc    <= ram_rd_en;
    ram_wr_en_dc    <= ram_wr_en;
    end
always @ (posedge clk)
	begin
	if (ram_en)
		begin
		if (ram_rd_en)
			memory[rd_addr] <= rd_data;
		if (ram_wr_en)
			wr_data_int <= memory[wr_addr];
		end
	end

always @ (posedge clk)
	begin
    wr_data <= wr_data_int;
	end


endmodule
