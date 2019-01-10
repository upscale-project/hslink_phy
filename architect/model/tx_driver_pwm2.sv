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


module tx_driver_pwm2 #(
  //parameter real tr=0, // transition time
  //parameter real dc=0,  // output dc value
  //parameter real amp=1.0,   // amplitude
  //parameter real wtap0 = 1.0,
  //parameter real wtap1 = 1.0
  parameter real Tunit = 5e-12
) (
  input in,       // TX data
  input clk,      // TX clock
  `output_pwl out  // TX output
);

//localparam real wtap[] = '{wtap0,wtap1};

`get_timeunit
PWLMethod pm=new;

logic clk_div;
logic [3:0]sr;
logic [3:0]DTC; 
logic vout;

divider #(.Ndiv(4)) idiv(.cki(clk), .cko(clk_div));

initial begin
sr ='0;
vout=0;
end

always @(posedge clk) begin
sr[0] <= in;
sr[1] <= sr[0];
sr[2] <= sr[1];
sr[3] <= sr[2];
end

always @(posedge clk_div) begin
DTC <=sr;
vout <= #((DTC*Tunit)*1s) ~vout;
end


bit2pwl #( .vh(0.5), .vl(-0.5), .tr(10e-12), .tf(10e-12) ) iB2P ( .in(vout), .out(out) );

//fir_ntap_filter #( .Ntap(2), .dc(0.0), .amp(amp), .wtap(wtap), .tr(10e-12) ) iPREEMPHASIS ( .clk(clk), .in(in), .out(out) );

endmodule
