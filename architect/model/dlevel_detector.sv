/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : cdr_adaptation_bdrate.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Data level detector for aux PD
  - This is sign-sign LMS adaptation
  - Slice index 0 of data will be used

* Note       :
  - 

* Todo       :
  - 

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dlevel_detector #(
// parameters here
  parameter integer Nadc = 8, // adc resolution
  parameter integer Nfr = 10, // bit width of fractional bit of mu
  parameter real mu = 0.008   // dv of adaptation adjustment ( mu >= 1.0/2^FP_Q)
) (
// I/Os here
  input clk,  // clock
  input rstn, // reset (active Lo)
  input signed [Nadc-1:0] din,  // data input
  output logic signed [Nadc-1:0] dlev // reference level for dfe adaptation
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////
localparam signed [Nfr-1:0] MU_FP = to_fpi(mu);  // fixed-point representation of "mu" parameter

//----- SIGNAL DECLARATION -----


//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

logic signed [Nadc-1:0] err;  // error signal of input
logic signed [1:0] sgn_err;  // sign of error signal
logic signed [1:0] sgn_err_d;  // signed rep. of partial sng_err for the next cycle
logic signed [1:0] sgn_err_aug[1:0]; // augment sgn_err for block processing
logic signed [1:0] sgn_d;
logic signed [1:0] sgn_d_d;  // signed rep. of partial sng_d for the next cycle
logic signed [1:0] sgn_d_aug[1:0]; // augment sgn_d for block processing

logic signed [Nadc+Nfr-1:0] dlev_fp; // fixed-point rep of dlev
logic signed [Nadc+Nfr-1:0] c_fp; // fixed-point rep of dfe coef's
logic signed [Nadc+Nfr-1:0] d_cal[1:0]; // product of mu*sgn(in)*sgn(err)

assign sgn_d_aug = {sgn_d, sgn_d_d};
assign sgn_err_aug = {sgn_err, sgn_err_d};

assign sgn_d = (din[Nadc-1])? -1 : +1;
assign err = (din[Nadc-1])? din + dlev : din - dlev;
assign sgn_err = (err[Nadc-1])? -1 : +1;
assign d_cal[0] = MU_FP*sgn_d_aug[1]*sgn_err_aug[1];
assign d_cal[1] = MU_FP*sgn_d_aug[0]*sgn_err_aug[1];
assign dlev = dlev_fp[Nadc+Nfr-1:Nfr];

always @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    // shift op
    sgn_d_d <= sgn_d;
    sgn_err_d <= sgn_err;
  end
  else begin
    sgn_d_d <= 0;
    sgn_err_d <= 0;
  end
end

always @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    dlev_fp <= 0;
    c_fp <= 0;
  end
  else begin
    dlev_fp <= dlev_fp + d_cal[0];
    c_fp <= c_fp - d_cal[1];
  end
end 

function signed [Nfr-1:0] to_fpi (input real in);
// convert a real value to an fixed-point integer in Q format
  return 2.0**Nfr*in;
endfunction

//pragma protect end
`endprotect

endmodule

