/****************************************************************

Copyright (c) 2018- Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : clock.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: It outputs a digital clock

* Note       :

* Revision   :
  - 7/26/2016: First release

****************************************************************/

//`timescale `DAVE_TIMEUNIT / `DAVE_TIMEUNIT

module clock_jitter #(
  parameter real freq = 1e9, // frequency
  parameter real duty = 0.5, // duty cycle
  parameter real td   = 0.0, // initial delay in second
  parameter      b0   = 1'b0, // initial value
  parameter real RJrms=1e-12, //RJ rms
  parameter real DJmax=1e-12, //DM max
  parameter integer random_seed=1
) (
  output ckout, // clock output
  output ckoutb, // ~ckout
  output logic ckout_jitter
);

`get_timeunit
PWLMethod pm=new;

real dt1, dt2;
integer seed1, seed2;
logic ck_temp;

initial begin
  seed1 = random_seed;
  seed2 = random_seed+1;
  dt1 = 0;
  dt2=0;
  ckout_jitter = b0;
  ck_temp =0;
end



pulse #(.b0(b0), .td(td), .tw(duty/freq), .tp(1.0/freq)) xpulse ( .out(ckout), .outb(ckoutb) );

always @(posedge ckout) begin
dt1 = DJmax*$dist_uniform(seed1, -0.5*1000, 0.5*1000)/(1.0*1000);
dt2 = RJrms*$dist_normal(seed2, 0, 1000)/(1.0*1000);
ckout_jitter <= #((1/freq+dt1+dt2)*1s) 1;
end

always @(negedge ckout) begin
ckout_jitter <= #((1/freq)*1s) 0;
end

 
endmodule

