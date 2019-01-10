/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : ti_adc_retimer.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Retiming time-interleaved adc outputs
  - This includes unsigned-to-signed conversion

* Note       :
  - 

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/

module ti_adc_retimer #(
	parameter integer Nadc=8,  // adc bits
	parameter integer Nti=5    // number of time-interleaved adc slices 
)( 
  input clk,  // clock
  input [Nadc-1:0] din[Nti-1:0], // adc outputs from all the slices
  output logic signed [Nadc-1:0] dout[Nti-1:0]  // retimed adc outputs
);

wire [Nadc-1:0] offset = {1'b1, {(Nadc-1){1'b0}}}; // for unsigned to signed conversion

always @(posedge clk)
  for (int i=0;i<Nti;i++) 
    dout[i] <= (din[i] - offset);

endmodule
