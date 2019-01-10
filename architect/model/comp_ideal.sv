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


module comp_ideal #(
parameter real t_off = 100e-12
) (
  `input_pwl in,       // TX data
  output logic out  // TX output
);

//localparam real wtap[] = '{wtap0,wtap1};

`get_timeunit
PWLMethod pm=new;

real t_err;
real volt, volt_prev;
real slope, slope_prev;
logic out_temp; 

initial
t_err=0;


always @(in.a) begin
volt <= in.a;
volt_prev = volt;
slope <= in.b;
slope_prev <= slope;

if (in.a >  0.0)
 out_temp<=  1;
// out<= #((t_off-t_err)*1s) 1;
else
 out_temp<=  0;
 //out<= #((t_off-t_err)*1s) 0;
end

always @(out_temp) begin
t_err=volt/slope_prev;
out <= #((t_off-t_err)*1s) out_temp;
end

endmodule
