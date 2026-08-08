/////////////////////////////////////////////////////////////////////////////////////////////
/// TSMC Library/IP Product
/// Filename: tphn28hpcpgv18.v
/// Technology: CLN28HT
/// Product Type: Standard I/O
/// Product Name: tphn28hpcpgv18
/// Version: 110a
////////////////////////////////////////////////////////////////////////////////////////////
////
///  STATEMENT OF USE
///
///  This information contains confidential and proprietary information of TSMC.
///  No part of this information may be reproduced, transmitted, transcribed,
///  stored in a retrieval system, or translated into any human or computer
///  language, in any form or by any means, electronic, mechanical, magnetic,
///  optical, chemical, manual, or otherwise, without the prior written permission
///  of TSMC.  This information was prepared for informational purpose and is for
///  use by TSMC's customers only.  TSMC reserves the right to make changes in the
///  information at any time and without notice.
///
////////////////////////////////////////////////////////////////////////////////////////////

`celldefine
module PCLAMP_G (VDDESD,VSSESD);
    inout   VDDESD,VSSESD;
    tran (VDDESD,VDDESD);
    tran (VSSESD,VSSESD);
endmodule
`endcelldefine

`celldefine
module PCLAMPC_H_G (VDDESD, VSSESD);
  inout VDDESD, VSSESD;
  tran (VDDESD, VDDESD);
  tran (VSSESD, VSSESD);
endmodule
`endcelldefine

`celldefine
module PCLAMPC_V_G (VDDESD, VSSESD);
  inout VDDESD, VSSESD;
  tran (VDDESD, VDDESD);
  tran (VSSESD, VSSESD);
endmodule
`endcelldefine

`celldefine
module PDB3A_H_G (AIO);
   inout AIO;
   tran (AIO,AIO);
endmodule
`endcelldefine

`celldefine
module PDB3A_V_G (AIO);
   inout AIO;
   tran (AIO,AIO);
endmodule
`endcelldefine

`celldefine
module PDB3AC_H_G (AIO);
   inout AIO;
   tran (AIO,AIO);
endmodule
`endcelldefine

`celldefine
module PDB3AC_V_G (AIO);
   inout AIO;
   tran (AIO,AIO);
endmodule
`endcelldefine

`celldefine
module PDDW04DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW04DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW04SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW04SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW08DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW08DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW08SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW08SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW12DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW12DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW12SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW12SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW16DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW16DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW16SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDDW16SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW04DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW04DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW04SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW04SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW08DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW08DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW08SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW08SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW12DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW12DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW12SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW12SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW16DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW16DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW16SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDUW16SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PDXOEDG_H_G (E, DS0, DS1, XIN, XOUT, XC);
    input E, DS0, DS1, XIN;
    output XC, XOUT;
    not    (XC, XOUT);
    nand   (XOUT, E, XIN);
    pmos   (DS0_tmp, DS0, 1'b0);
    pmos   (DS1_tmp, DS1, 1'b0);
    specify
      if (DS0 == 1'b0 && DS1 == 1'b0) (E => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (E => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (E => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (E => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b0) (E => XOUT)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (E => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (E => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (E => XOUT)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b0) (XIN => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (XIN => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (XIN => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (XIN => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b0) (XIN => XOUT)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (XIN => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (XIN => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (XIN => XOUT)=(0, 0);
    endspecify
endmodule
`endcelldefine

`celldefine
module PDXOEDG_V_G (E, DS0, DS1, XIN, XOUT, XC);
    input E, DS0, DS1, XIN;
    output XC, XOUT;
    not    (XC, XOUT);
    nand   (XOUT, E, XIN);
    pmos   (DS0_tmp, DS0, 1'b0);
    pmos   (DS1_tmp, DS1, 1'b0);
    specify
      if (DS0 == 1'b0 && DS1 == 1'b0) (E => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (E => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (E => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (E => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b0) (E => XOUT)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (E => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (E => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (E => XOUT)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b0) (XIN => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (XIN => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (XIN => XC)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (XIN => XC)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b0) (XIN => XOUT)=(0, 0);
      if (DS0 == 1'b0 && DS1 == 1'b1) (XIN => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b0) (XIN => XOUT)=(0, 0);
      if (DS0 == 1'b1 && DS1 == 1'b1) (XIN => XOUT)=(0, 0);
    endspecify
endmodule
`endcelldefine

`celldefine
module PENDCAP_G ();
endmodule
`endcelldefine

`celldefine
module PENDCAPA_G ();
endmodule
`endcelldefine

`celldefine
module PRCUT_G ();
endmodule
`endcelldefine

`celldefine
module PRCUTA_G ();
endmodule
`endcelldefine

`celldefine
module PRDW08DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW08DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW08SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW08SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW12DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW12DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW12SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW12SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW16DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW16DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW16SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRDW16SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b0, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b0, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW08DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW08DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW08SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW08SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW12DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW12DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW12SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW12SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW16DGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW16DGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW16SDGZ_H_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PRUW16SDGZ_V_G (I, OEN, REN, PAD, C);
  input I, OEN, REN;
  inout PAD;
  output C;

  wire   MG, pull_pad, pull_c;
  parameter PullTime = 10000;
 
  bufif0 (PAD_q, I, OEN);
  pmos   (MG, PAD_q, 1'b0);
  bufif1 (weak1, weak0) (PAD_i, 1'b1, pull_pad);
  pmos   (MG, PAD_i, 1'b0);
  pmos   (PAD, MG, 1'b0);
  bufif1 (C_buf, PAD, 1'b1);
  bufif1 (weak0,weak1) (C_buf, 1'b1, pull_c);
  buf    (C, C_buf);
  not    (RE, REN);
  buf    #(PullTime,0) (pull_pad, RE);
  buf    (pull_c, RE);

`ifdef TETRAMAX
`else
  always @(PAD) begin
    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") && $countdrivers(PAD))
      $display("%t ++BUS CONFLICT++ : %m", $realtime);
  end

  specify
    (I => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => C)=(0, 0);
  endspecify
`endif
endmodule
`endcelldefine

`celldefine
module PVDD1A_H_G (AVDD);
    inout   AVDD;
    tran (AVDD,AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD1A_V_G (AVDD);
    inout   AVDD;
    tran (AVDD,AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD1AC_H_G (AVDD);
    inout   AVDD;
    tran (AVDD,AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD1AC_V_G (AVDD);
    inout   AVDD;
    tran (AVDD,AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD1ANA_H_G (AVDD);
  inout AVDD;
  tran (AVDD, AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD1ANA_V_G (AVDD);
  inout AVDD;
  tran (AVDD, AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD1DGZ_H_G (VDD);
    inout   VDD;
    tran (VDD,VDD);
endmodule
`endcelldefine

`celldefine
module PVDD1DGZ_V_G (VDD);
    inout   VDD;
    tran (VDD,VDD);
endmodule
`endcelldefine

`celldefine
module PVDD2ANA_H_G (AVDD);
  inout AVDD;
  tran (AVDD, AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD2ANA_V_G (AVDD);
  inout AVDD;
  tran (AVDD, AVDD);
endmodule
`endcelldefine

`celldefine
module PVDD2DGZ_H_G (VDDPST);
    inout   VDDPST;
    tran (VDDPST,VDDPST);
endmodule
`endcelldefine

`celldefine
module PVDD2DGZ_V_G (VDDPST);
    inout   VDDPST;
    tran (VDDPST,VDDPST);
endmodule
`endcelldefine

`celldefine
module PVDD2POC_H_G (VDDPST);
  inout VDDPST;
  tran (VDDPST, VDDPST);
endmodule
`endcelldefine

`celldefine
module PVDD2POC_V_G (VDDPST);
  inout VDDPST;
  tran (VDDPST, VDDPST);
endmodule
`endcelldefine

`celldefine
module PVDD3A_H_G (AVDD,TAVDD);
    inout   AVDD,TAVDD;
    tran (AVDD,TAVDD);
endmodule
`endcelldefine

`celldefine
module PVDD3A_V_G (AVDD,TAVDD);
    inout   AVDD,TAVDD;
    tran (AVDD,TAVDD);
endmodule
`endcelldefine

`celldefine
module PVDD3AC_H_G (AVDD,TACVDD);
    inout   AVDD,TACVDD;
    tran (AVDD,TACVDD);
endmodule
`endcelldefine

`celldefine
module PVDD3AC_V_G (AVDD,TACVDD);
    inout   AVDD,TACVDD;
    tran (AVDD,TACVDD);
endmodule
`endcelldefine

`celldefine
module PVSS1A_H_G (AVSS);
    inout   AVSS;
    tran (AVSS,AVSS);
endmodule
`endcelldefine

`celldefine
module PVSS1A_V_G (AVSS);
    inout   AVSS;
    tran (AVSS,AVSS);
endmodule
`endcelldefine

`celldefine
module PVSS1AC_H_G (AVSS);
    inout   AVSS;
    tran (AVSS,AVSS);
endmodule
`endcelldefine

`celldefine
module PVSS1AC_V_G (AVSS);
    inout   AVSS;
    tran (AVSS,AVSS);
endmodule
`endcelldefine

`celldefine
module PVSS1ANA_H_G (AVSS);
  inout AVSS;
  tran (AVSS, AVSS);
endmodule

`endcelldefine

`celldefine
module PVSS1ANA_V_G (AVSS);
  inout AVSS;
  tran (AVSS, AVSS);
endmodule

`endcelldefine

`celldefine
module PVSS1DGZ_H_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS1DGZ_V_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS2A_H_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS2A_V_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS2AC_H_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS2AC_V_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS2ANA_H_G (AVSS);
  inout AVSS;
  tran (AVSS, AVSS);
endmodule

`endcelldefine

`celldefine
module PVSS2ANA_V_G (AVSS);
  inout AVSS;
  tran (AVSS, AVSS);
endmodule

`endcelldefine

`celldefine
module PVSS2DGZ_H_G (VSSPST);
    inout   VSSPST;
    tran (VSSPST,VSSPST);
endmodule
`endcelldefine

`celldefine
module PVSS2DGZ_V_G (VSSPST);
    inout   VSSPST;
    tran (VSSPST,VSSPST);
endmodule
`endcelldefine

`celldefine
module PVSS3A_H_G (AVSS,TAVSS);
    inout   AVSS,TAVSS;
    tran (AVSS,TAVSS);
endmodule
`endcelldefine

`celldefine
module PVSS3A_V_G (AVSS,TAVSS);
    inout   AVSS,TAVSS;
    tran (AVSS,TAVSS);
endmodule
`endcelldefine

`celldefine
module PVSS3AC_H_G (AVSS,TACVSS);
    inout   AVSS,TACVSS;
    tran (AVSS,TACVSS);
endmodule
`endcelldefine

`celldefine
module PVSS3AC_V_G (AVSS,TACVSS);
    inout   AVSS,TACVSS;
    tran (AVSS,TACVSS);
endmodule
`endcelldefine

`celldefine
module PVSS3DGZ_H_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

`celldefine
module PVSS3DGZ_V_G (VSS);
    inout   VSS;
    tran (VSS,VSS);
endmodule
`endcelldefine

