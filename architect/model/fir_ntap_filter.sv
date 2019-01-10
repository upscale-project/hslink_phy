/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : fir_ntap_filter.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: N-tap FIR filter with analog output
  - 

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module fir_ntap_filter #(
// parameters here
  parameter integer Ntap = 1, // # of taps
  parameter real dc = 0,      // dc offset of the analog output 
  parameter real amp=1.0,     // amplitude
  parameter real wtap[Ntap] = '{{Ntap}{1.0}}, // tap weight
  parameter real tr = 10e-12  // transition time
) (
// I/Os here
  input logic clk,  // clock
  input logic in,   // serial digital data input
  `output_pwl out   // FIR output
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----
logic [Ntap-1:0] sr;  // shift register

pwl _pp[Ntap]; // partial product of FIR
real _k_pp[Ntap] = '{{Ntap}{1.0}};

genvar i;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

always @(posedge clk) sr <= {sr, in}; // shift op.

generate  // generate partial product for each input bit
  for ( i=0; i< Ntap; i++) begin: iDAC
    dac_1b #( .vh(0.5*amp*wtap[i]+dc), .vl(-0.5*amp*wtap[i]+dc), .tr(tr) ) iDAC1B ( .in(sr[i]), .out(_pp[i]) );
  end
endgenerate

pwl_add #( .no_sig(Ntap) ) iADD_PP ( .scale(_k_pp), .in(_pp), .out(out) ); // add partial products


//pragma protect end
`endprotect

endmodule

