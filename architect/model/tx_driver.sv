/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#. Contact #EMAIL# for details.

* Filename   : tx_driver.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Tx driver 

* Note       :

* Revision   :
  - 7/26/2016: First release

****************************************************************/


module tx_driver #(
  parameter real tr=0, // transition time
  parameter real dc=0,  // output dc value
  parameter real amp=1.0,   // amplitude
  parameter real wtap0 = 1.0,
  parameter real wtap1 = 1.0
) (
  input in,       // TX data
  input clk,      // TX clock
  `output_pwl out  // TX output
);

localparam real wtap[] = '{wtap0,wtap1};

`get_timeunit
PWLMethod pm=new;

fir_ntap_filter #( .Ntap(2), .dc(0.0), .amp(amp), .wtap(wtap), .tr(tr) ) iPREEMPHASIS ( .clk(clk), .in(in), .out(out) );

endmodule
