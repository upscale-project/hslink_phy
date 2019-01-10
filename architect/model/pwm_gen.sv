/****************************************************************

Copyright (c) 2018- Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : prbs21.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description:
  - Pseudo random bit sequence (run length of 21) generator.

* Note       :

* Revision   :
  - 7/26/2016: First release
  
****************************************************************/

module pwm_gen (
  input clk,  // clock
  input rst,  // reset (act. high)
  output out  // output stream
);

timeunit `DAVE_TIMEUNIT ;
timeprecision `DAVE_TIMEUNIT ;

logic sr;

initial 
sr =0;

always @(posedge clk or posedge rst) begin
  if(rst) sr <= 0;
  else begin
    sr <= ~sr;
  end
end

assign out = sr;

endmodule
