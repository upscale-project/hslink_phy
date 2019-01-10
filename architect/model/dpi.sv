/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : dpi.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Digitally-controlled phase interpolator
  -

* Note       :
  - It assumes that clk_lead always leads clk_lag in phase
  - "tdi" must be larger than the time difference between the 
    two incoming clocks, which is checked in the model.

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dpi #(
// parameters here
  parameter integer Nbit = 6,  // # of control bit
  parameter real tdi = 100e-12 // intrinsic delay
) (
// I/Os here
  input logic cki_lead, //  lead clock
  input logic cki_lag,  //  lag clock
  input logic [Nbit-1:0] ctl, // pi control
  output logic cko     // phase-interpolated clock
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----
real t0, ti, ti_w;
real wgt;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

// make sure tdi > ti_w
always @(tdi, ti_w)
  assert (tdi > ti_w) else $error("%m: tdi (%f [psec]) is less than ti_w(%f [psec])", tdi/1e-12, ti_w/1e-12);

// compute phase interpolation weight
assign wgt = $itor(ctl/2.0**Nbit);

// compute delay
always @(cki_lead, cki_lag) 
  if (cki_lead ^ cki_lag) // one of the clock transits
    t0 = `get_time;
  else begin
    ti = `get_time - t0;
    ti_w = ti * wgt;
  end
initial cko = 0;
// schedule an event for interpolated output
always @(cki_lead) cko <= `delay(tdi+ti_w) cki_lead;


//pragma protect end
`endprotect

endmodule

