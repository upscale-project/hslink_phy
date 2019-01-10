/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : clk_iq_div.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Frequency divider (/2) to generate I/Q clocks 
  - cko[0] : I clock
  - cko[1] : Q clock
  - cko[2] : ~I clock
  - cko[3] : ~Q clock

* Note       :
  - The frequency of cko is half of the cki.

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module clk_iq_div #(
// parameters here
) (
// I/Os here
  input cki,
  input rstn, // reset (act Lo)
  output [3:0] cko
);

///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----

logic clk_i = 1'b0;
logic clk_q = 1'b0;


//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

always @(posedge cki or negedge rstn)   
  if (!rstn) clk_i <= 1'b0;
  else clk_i <= ~clk_i;
always @(negedge cki or negedge rstn) 
  if (!rstn) clk_q <= 1'b0;
  else clk_q <= clk_i;

assign cko[0] = clk_i;
assign cko[1] = clk_q;
assign cko[2] = ~clk_i;
assign cko[3] = ~clk_q;


//pragma protect end
`endprotect

endmodule

