/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#. Contact #EMAIL# for details.

* Filename   : dx_phase_slicer.sv
* Author     : Byongchan Lim (bclim21@gmail.com)
* Description: 
  Slicing phase to create a clock

* Note       :

* Revision   :
  - 00/00/0000: First release

****************************************************************/

module dx_phase_slicer #(
) (
  `input_real phase_1, // thresholds of phase slicing
  `input_real phase_0, // thresholds of phase slicing
  `input_pwl phase,        // phase input
  output logic cko, ckob   // (+)/(-) clocks
);

timeunit `DAVE_TIMEUNIT ;
timeprecision `DAVE_TIMEUNIT ;

`get_timeunit     // get time unit and assign it to TU
PWLMethod pm=new; // class contains method for PWL signal

`protect
//pragma protect 
//pragma protect begin

// wires
pwl PWL1 = `PWL1;
real _ph;     // current phase value
real dTr;     // delta t for scheduling an event
event wakeup; // event signal
real t0;      // 
real ph_targ; // 
time t_prev, dTm, dT, t0m;

initial t_prev = 0;
initial dT = 0;

// predict the firing time and compare 
always @(`pwl_event(phase) or phase.t0) begin
  t_prev = $time;
  dT = 0;
  ->> wakeup;
end

always @(wakeup) begin
  t0 = `get_time;
  t0m = $time;
  dTm = t0m - t_prev;
  if (dT == dTm) begin
    t_prev = t0m;
    _ph = pm.eval(phase, t0);
    if (phase_1 > phase_0) begin
      if (_ph < phase_1 && _ph >= phase_0) begin
        cko = 1'b0; ckob = 1'b1;
      end
      else begin
        cko = 1'b1; ckob = 1'b0;
      end
      if (_ph < phase_1) begin  // schedule event
        if (_ph < phase_0) ph_targ = phase_0;
        else ph_targ = phase_1;
        dTr = max(TU,(ph_targ-_ph)/phase.b);
        dT = time'(dTr/TU);
        ->> #(dT) wakeup;
      end
    end
    else begin
      if (_ph < phase_0 && _ph >= phase_1) begin
        cko = 1'b1; ckob = 1'b0;
      end
      else begin
        cko = 1'b0; ckob = 1'b1;
      end
      if (_ph < phase_0) begin  // schedule event
        if (_ph < phase_1) ph_targ = phase_1;
        else ph_targ = phase_0;
        dTr = max(TU,(ph_targ-_ph)/phase.b);
        dT = time'(dTr/TU);
        ->> #(dT) wakeup;
      end
    end
  end
end

//pragma protect end
`endprotect

endmodule
