/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : clkgen_mph.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Multi(Np)-phase clock generation
  -

* Note       :
  - If Np < 2, cko = cki

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module clkgen_mph #(
// parameters here
  parameter integer Np = 2, // number of phase
  parameter [Np-1:0] init = 1 // initial value of outputs 
) (
// I/Os here
  input cki,  // master clock
  output [Np-1:0] cko // Np-phase clock outputs
);


///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----

logic [Np-1:0] _cko;

initial _cko = init;  // initialize
assign cko = (Np>=2) ? _cko : cki;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

always @(cko) // ensure that cko is always one-hot 
  if (Np >= 2)
    assert ($onehot(cko)) else $error("%m: The clock output (%b) is not one-hot", cko);

// circular shift op. to generate multi-phase clock
always @(posedge cki) 
  if (Np >= 2)
    _cko <= {cko[Np-2:0], cko[Np-1]};
  else
    _cko <= 1'b0;


//pragma protect end
`endprotect

endmodule

