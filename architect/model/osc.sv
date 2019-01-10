/****************************************************************

Copyright (c) 2018 Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University.

* Filename   : osc.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Multi-phase oscillator (e.g. I/Q clock generator)
  -

* Note       :
  - 

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/

module osc #(
  parameter integer Nph = 1,           // number of clock phases
  parameter real duty_cycle[] = '{(Nph){0.5}},  // duty cycle
  parameter real ph_offset[] = '{(Nph){0.0}},  // phase offset in [rad] from each ideal position 
  parameter real etol_phase = 0.01  // error tolerance of a phase variable in [rad]
) (
  `input_pwl freq,  // frequency
  input logic reset,  // reset oscillator to 0 rad
  output logic [Nph-1:0] cko, // output clock
  output logic [Nph-1:0] ckob // ~cko
);

pulldown(reset);

///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----
pwl RESET_VAL = '{0.95,0,0};  // when reset is asserted, set the output phase to this value 
genvar j;
pwl phase;      // phase
real phase_mod; // modulo of phase
real ph_thres[Nph-1:0]; // thresholds of phase slicing for generating clocks
logic trigger;
real ph_th_1[Nph-1:0];
real ph_th_0[Nph-1:0];

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

// produce a phase
pwl_integrator_w_reset #( .etol(etol_phase/`M_TWO_PI), .modulo(1.0), .noise(0.0) ) iPHASE_INTEG ( .gain(1.0), .si(freq), .so(phase), .trigger(trigger), .i_modulo(phase_mod), .reset(reset), .reset_sig(RESET_VAL) );

// determine thresholds of phase slicers for rising edges of clocks
always @(posedge trigger)
  for (int i=0;i<Nph;i++) begin
    ph_th_1[i] = $itor(i)/$itor(Nph)*phase_mod + ph_offset[i]/`M_TWO_PI;
    ph_th_0[i] = ph_rollover(ph_th_1[i] + phase_mod*duty_cycle[i], phase_mod);
  end

generate
  for (j=0;j<Nph;j++) begin: uSLICER
    phase_slicer uPS (.phase_1(ph_th_1[j]), .phase_0(ph_th_0[j]), .phase(phase),
                      .cko(cko[j]), .ckob(ckob[j]));
  end
endgenerate

function real ph_rollover(input real ph, input real modulo);
begin
  if (ph > modulo) ph_rollover = ph - modulo;
  else ph_rollover = ph;
end
endfunction

//pragma protect end
`endprotect

endmodule

/****************************************************************

Copyright (c) 2018 Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. 

* Filename   : phase_slicer.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: 
  Slicing phase to create a clock

* Note       :

* Revision   :
  - 00/00/0000: First release

****************************************************************/

module phase_slicer #(
) (
  `input_real phase_1, // thresholds of phase slicing
  `input_real phase_0, // thresholds of phase slicing
  `input_pwl phase,        // phase input
  output logic cko, ckob   // (+)/(-) clocks
);

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
        if (phase.b != 0.0)
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
        if (phase.b != 0.0)
          ->> #(dT) wakeup;
      end
    end
  end
end

//pragma protect end
`endprotect

endmodule
