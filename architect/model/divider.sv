/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#. Contact #EMAIL# for details.

* Filename   : divider.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: frequency divider 

* Note       :

* Revision   :
  - 7/26/2016: First release

****************************************************************/


module divider #(
  parameter integer Ndiv = 2  // divider ratio
) (
  input cki,  // input clock
  output cko  // divided clock
);

localparam Nbw = $clog2(Ndiv);
 integer hNdiv = Ndiv >> 1; // about half of Ndiv

logic [Nbw-1:0] cntr = 0;

always @(posedge cki) 
  if (cntr == Ndiv-1) cntr <= '0;
  else cntr <= cntr+ 1;

assign cko = (cntr >= hNdiv) ? 1'b1 : 1'b0;

endmodule
