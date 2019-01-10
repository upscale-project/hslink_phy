/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : dpi_filter.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Loop filter for PI control
  -

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dpi_filter #(
// parameters here
    parameter integer Nlf = 14, // width of out (Nlf-Npi) is fractional number part
    parameter integer Nadc = 8,    // adc resolution
    parameter integer Npi = 8,     // number of PI-bits / UI
    parameter real Kp=0.25         // proportional gain
) (
// I/Os here
  input clk,       // triggering clock
  input sel_ext, // enable loop filter
  input signed [Nadc-1:0] in, // output phase error signal from mmpd
  input [Npi-1:0] pi_ctl_ext, // external control value (valid when sel_ext == Hi)
  output [Npi-1:0] out        // PI control output
);


///////////////////
// CODE STARTS HERE
///////////////////
localparam integer Nlff = (Nlf-Npi);  // number of fractional bits in LF state

//----- SIGNAL DECLARATION -----
//logic signed [Nlf-1:0] K_P = to_fpi(Kp);
logic signed [Nlf-1:0] K_P = 1;
logic signed [Nlf-1:0] out_reg;
logic signed [Nlf-1:0] pro_path;

assign out = sel_ext ? pi_ctl_ext : out_reg[Nlf-1:Nlff];
assign pro_path = K_P*in >>> 4;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

always @(posedge clk) // integrate proportional part
  if (!sel_ext) out_reg  <= out_reg + pro_path;
  else out_reg <= pi_ctl_ext << Nlff;

//----
function signed [Nlf-1:0] to_fpi (input real in);
// convert a real value to an fixed-point integer in Q format
  return 2.0**(Nlff)*in;
endfunction

//pragma protect end
`endprotect

endmodule

