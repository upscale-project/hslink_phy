/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : dac_1b.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: 1-bit DAC
  -

* Note       :
  - Assume symmetric rise/fall transition time 

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dac_1b #(
// parameters here
  parameter real vh = 1.0,  // output corresponds to high value
  parameter real vl = 0.0,  // output corresponds to low value
  parameter real tr = 1e-9  // transition time
) (
// I/Os here
  input logic in, // 1-bit input
  `output_pwl out // analog output
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----


//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

bit2pwl #( .vh(vh), .vl(vl), .tr(tr), .tf(tr) ) iB2P ( .in(in), .out(out) );

//pragma protect end
`endprotect

endmodule

