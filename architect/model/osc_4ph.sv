/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : osc_4ph.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: An oscillator that generates I/Q clocks 
  - cko[0] : I clock
  - cko[1] : Q clock
  - cko[2] : ~I clock
  - cko[3] : ~Q clock

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module osc_4ph #(
// parameters here
  parameter real freq = 10e9, // frequency
  parameter real etol_phase = 0.01  // phase error tolerance in [rad]
) (
// I/Os here
  output logic [3:0] cko
);

localparam integer mph = 4;

///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----

pwl i_freq = '{freq, 0, 0};

//----- FUNCTIONAL DESCRIPTION -----

osc #( .Nph(mph), .duty_cycle('{(mph){0.5}}), .ph_offset('{(mph){0.0}}), .etol_phase(etol_phase) ) iOSC ( .freq(i_freq), .cko(cko), .ckob() );

endmodule

