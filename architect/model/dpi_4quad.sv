/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : dpi_4quad.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: 4-quadrant phase interpolator
  - cki[0] : I clock
  - cki[1] : Q clock
  - cki[2] : ~I clock
  - cki[3] : ~Q clock

* Note       :
  - NBit is the PI resolution per quadrant (NOT per UI)

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dpi_4quad #(
// parameters here
  parameter integer Nbit=5, // PI resolution per quadrant
  parameter real tdi = 100e-12 // intrinsic delay of a DPI
) (
// I/Os here
  input [3:0] cki, // I/Q clock inputs
  input [Nbit+1:0] ctl, // PI control, MSB 2-bits: select quadrant, LSB bits: PI weight control
  output cko  // interpolated clock output
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----
logic [1:0] quadrant;  // quadrant of clock phase
logic ck_lead, ck_lag;  // lead/ lag clocks for a selected quadrant
logic [Nbit+1:0] ctl_selected;

assign quadrant = ctl[Nbit+1:Nbit];

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

// Select lead/lag clocks
always @(*)
  case (quadrant)
    0: begin
      ck_lead = cki[0];
      ck_lag  = cki[1];
    end
    1: begin
      ck_lead = cki[1];
      ck_lag  = cki[2];
    end
    2: begin
      ck_lead = cki[2];
      ck_lag  = cki[3];
    end
    3: begin
      ck_lead = cki[3];
      ck_lag  = cki[0];
    end
  endcase

// PI for a quadrant
dpi #( .Nbit(Nbit), .tdi(tdi) ) iDPI ( .cki_lead(ck_lead), .cki_lag(ck_lag), .ctl(ctl[Nbit-1:0]), .cko(cko) );

//pragma protect end
`endprotect

endmodule

