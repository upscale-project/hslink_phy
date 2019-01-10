/****************************************************************

Copyright (c) 2016-2017 Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : digital_lf.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: PI digital loop filter in Rx PLL
  - It is implemented as an integrator with a proportional gain

* Note       :
  - 

* Revision   :
  - 7/26/2016: First release

****************************************************************/


module digital_lf #(
    parameter integer LF_BIT = 14,      // width of out (LF_BIT-(PI_BIT+2)) is fractional number part
    parameter integer ADC_BIT = 8,      // adc resolution
    parameter integer PI_BIT = 8,       // PI resolution / quadrant
    parameter integer Nl = 4,           // loop filter latency
    parameter [PI_BIT-1:0] offset=0,  // control offset
    parameter real Kp=0.25,             // proportional gain
    parameter integer LF_FRAC_BIT = (LF_BIT-PI_BIT)
)(
    input clk,                     // triggering clock
    input filter_en,
    input signed [ADC_BIT-1:0] in,                      // output signed signal from mmpd
    output [PI_BIT-1:0] out       // output signal
);

`get_timeunit
// internally, this runs Nbit + 10
// The upper Nbit will be taken for "out"

logic [LF_BIT-1:0] i_offset = offset << LF_FRAC_BIT;
logic signed [LF_BIT-1:0] K_P = to_fpi(Kp);

// variables
reg signed [LF_BIT-1:0] out_reg;
wire signed [LF_BIT-1:0] pro_path;

assign out = filter_en? out_reg[LF_BIT-1:LF_FRAC_BIT] : i_offset[LF_BIT-1:LF_FRAC_BIT] ;

// bang-bang op also works though
//logic signed [1:0] in_sgn;
//assign in_sgn = in[ADC_BIT-1] ? -1 : 1;

assign pro_path = K_P*in;
always @(posedge clk or negedge filter_en) // integrate proportional part
  if (!filter_en) out_reg <= i_offset;
  else out_reg  <= out_reg + pro_path;

function signed [LF_BIT-1:0] to_fpi (input real in);
// convert a real value to an fixed-point integer in Q format
logic signed [LF_BIT-1:0] out;
begin
  return 2.0**(LF_FRAC_BIT)*in;
end
endfunction

endmodule
