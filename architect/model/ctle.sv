/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#. Contact #EMAIL# for details.

* Filename   : ctle.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Continuous-time linear equalizer with DC gain
  - It is represented as a dc gain stage followed by a filter having
    a zero and two poles.

* Note       :
  - The gain compression is not incorporated.
  - The second-order filter is represented as a sum of two
    partial fraction terms.
  - This might result in convervative residual errors than 
    using "pwl_filter_real".
  - Two poles should be apart by a non-zero value.

* Revision   :
  - 0/00/2018: First release

****************************************************************/


module ctle #(
  parameter real etol=0.001, // error tolerance of PWL approximation
  parameter real av = 1.00,   // dc gain
  parameter real fz1 = 800e6, // zero in Hz
  parameter real fp1 = 4e9, // 1st pole in Hz
  parameter real fp2 = 5e9    // 2nd pole in Hz
) ( 
  `input_pwl in,
  `output_pwl out
);

`get_timeunit

// convert Hz to Rad
localparam real wz1 = `M_TWO_PI*fz1;
localparam real wp1 = `M_TWO_PI*fp1;
localparam real wp2 = `M_TWO_PI*fp2;

// compute coefficients of PFEs
localparam real K = wp1*wp2/wz1;
complex A1 = '{K*(fz1-fp1)/(fp2-fp1),0};
complex A2 = '{-K*(fz1-fp2)/(fp2-fp1),0};
complex B1 = '{wp1,0};
complex B2 = '{wp2,0};

pwl in_1;
pwl out_1, out_2, out_3;

real scale[2];
pwl in_add[2];
assign scale = '{1.0, 1.0};
assign in_add = '{out_1, out_2};

pwl_vga iDCGAIN ( .scale(av), .in(in), .out(in_1) );  // dc gain
pwl_filter_pfe #( .etol(etol/2.0), .en_filter(1'b1) ) iPFE1 ( .A(A1), .B(B1), .in(in_1), .out(out_1) );  // 1st PFE
pwl_filter_pfe #( .etol(etol/2.0), .en_filter(1'b1) ) iPFE2 ( .A(A2), .B(B2), .in(in_1), .out(out_2) );  // 1st PFE
pwl_add #( .no_sig(2) ) iADD ( .scale(scale), .in(in_add), .out(out_3) ); // add two PFEs
pwl_event_filter #( .etol(etol) ) iEVTF ( .in(out_3), .out(out) );  // event filtering

endmodule
