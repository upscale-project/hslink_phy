/****************************************************************

Copyright (c) 2016-2017 Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : channel.v
* Description: Reduced-order model for measured channel behavior

****************************************************************/

module channel #(
  parameter real etol = 0.001 // error tolerance of PWL approximation
) (
  `input_pwl in, `output_pwl out
);

`get_timeunit
PWLMethod pm=new;

pwl out_arr[0:(${N}-1)];
pwl out_imm;

${filters}
real channel_delay;
real scale[0:(${N}-1)] = ${scale};
pwl_add #(.no_sig(${N})) add_i(.in(out_arr), .scale(scale), .out(out_imm));

pwl_delay #(.delay(${delay})) delay_i(.in(out_imm), .out(out));
endmodule
