`timescale 1ns / 1ps

module bufg_ctrl(
   output O,
   input I0,
   input I1,
   input S
    );
    
    BUFGMUX_CTRL BUFGMUX_CTRL_inst (
      .O(O),   // 1-bit output: Clock output
      .I0(I0), // 1-bit input: Clock input (S=0)
      .I1(I1), // 1-bit input: Clock input (S=1)
      .S(S)    // 1-bit input: Clock select
   );

    
endmodule
