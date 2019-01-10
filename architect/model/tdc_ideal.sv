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


module tdc_ideal #(
parameter real t_res = 1e-12
) (
  input in,       // TX data
  output int out  // TX output
);

//localparam real wtap[] = '{wtap0,wtap1};

`get_timeunit
PWLMethod pm=new;

real t_start, t_stop, t_diff, t_diff_prev, t_diff_diff;

always @(posedge in) begin
t_start = $realtime*1e-15;
end

always @(negedge in) begin
t_stop = $realtime*1e-15;
t_diff = t_stop-t_start;
t_diff_prev<=t_diff;
t_diff_diff = t_diff-t_diff_prev;

out<=(floor(t_diff/t_res)) ;
end


endmodule
