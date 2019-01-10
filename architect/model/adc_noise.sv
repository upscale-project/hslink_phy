/***********************************************************

Copyright (c) 2018- Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : adc.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Date       : 00/00/2016
* Description: Ideal synchronous ADC

* Note       :

* Todo       :

* Revision   :
  - 7/26/2016: First release

***********************************************************/


module adc_noise #(
// parameters here
  parameter integer BITW=8, // bit width of digital output
  parameter integer BITW_true=6,
  parameter integer random_seed=2
) (
// I/Os here
  `input_real out_min,  // min value of input
  `input_real out_max,  // max value of input
  `input_pwl in,        // analog input
  input clk,            // clock
  output logic [BITW-1:0] dout // digital output
);

//timeunit `DAVE_TIMEUNIT;
//timeprecision `DAVE_TIMEUNIT;

`get_timeunit
PWLMethod pm=new;

`protect
//pragma protect 
//pragma protect begin

///////////////////
// CODE STARTS HERE
///////////////////

// wires, assignment
real fscale;  // full scale
real mid_pt;
real dv;
real sampled;
real sampled_os;
logic bitout;
event wakeup;
real lsb;
real qnoise;
integer seed;


// body
initial begin
seed =  random_seed;
qnoise = 0.0;
end

//initial #1 -> wakeup;  // for ncsim

always @(out_min or out_max or wakeup) begin
  fscale = out_max - out_min;
  mid_pt = fscale/2.0;
  //lsb = fscale/(2.0**BITW);
  lsb = fscale/(2.0**BITW_true);						// mod by sjkim
end

always @(posedge clk) begin
  qnoise = lsb*$dist_uniform(seed, -0.5*1000, 0.5*1000)/(1.0*1000); 
  sampled = pm.eval(in, `get_time) + qnoise ; 	// mod by sjkim
  sampled_os = sampled - out_min;
  for(int i=BITW-1;i>=0;i--) begin
      dv = sampled_os - mid_pt;
      bitout = (dv > 0.0);
      if (bitout) sampled_os = dv;
      sampled_os = 2.0*sampled_os;
      dout[i] <= bitout;
  end
end

//pragma protect end
`endprotect
endmodule

