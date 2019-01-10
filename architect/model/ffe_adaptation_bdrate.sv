/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : ffe_adaptation_bdrate.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Adaptation logic for a baud-rate digital FFE
  - This is sign-sign LMS adaptation
  - per-slice adaptation which might be useful for canceling out
    mismatches between slices.

* Note       :
  - To disable FFE, one can drive 0 values of FFE coefficients 
    externally and select them by setting sel_ext == Hi

* Todo       :

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module ffe_adaptation_bdrate #(
// parameters here
  parameter integer Nadc = 8, // adc resolution
  parameter integer  Nti = 1, // total number of slices
  parameter real  mu = 0.008, // dv of adaptation adjustment ( mu >= 1.0/2^FP_Q)
  parameter integer Ntap = 3, // number of FFE taps
  parameter integer Mtap = 1, // index of main tap (index starts from zero)
                              // 0 <= Mtap < Ntap
  parameter integer Nint= 10, // bit width of integer bit of coefficients
  parameter integer Nfr = 10  // bit width of fractional bit of coefficients
) (
// I/Os here
  input clk,  // clock
  input enable, // enable (active Hi)
  input signed [Nadc-1:0] din[Nti-1:0],  // data input
  input sel_ext,  // select ffe_coefficient (Hi: external value, Lo: value from this adaptation logic)
  //input signed [Nint+Nfr-1:0] ffe_coef_ext[Ntap-1:0], // external ffe coef's for each slice
  //output signed [Nint+Nfr-1:0] ffe_coef[Ntap-1:0]  // external ffe coef's for each slice
  input real ffe_coef_ext[Ntap-1:0], 												//mod by sjkim 
  output real ffe_coef[Ntap-1:0]  												// mod by sjkim
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////
localparam signed [Nfr-1:0] MU_FP = to_fpi(mu);  // fixed-point representation of "mu" parameter
localparam integer quo = $ceil(real'(Ntap)/real'(Nti));

genvar j, k;
integer i;

//----- SIGNAL DECLARATION -----

//logic signed [Nint+Nfr-1:0] i_ffe_coef[Ntap-1:0]; // external ffe coef's 
real dlev_fp;
real i_ffe_coef[Ntap-1:0]; 												// mod by sjkim 

assign ffe_coef = sel_ext ? ffe_coef_ext : i_ffe_coef;  // select ffe coefficients

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

logic signed [Nadc-1:0] din_d[quo*Nti-1:0];  // signed rep. of partial din for the next cycle
logic signed [Nadc-1:0] din_aug[Nti+Ntap-1:0]; // augment sgn_d for block processing
logic signed [1:0] sgn_d[Nti+Ntap-1:0]; // augment sgn_d for block processing

logic signed [Nadc-1:0] err;  // error signal of input
logic signed [1:0] sgn_err;  // sign of error signal

logic signed [Nadc-1:0] _tmp[quo*Nti-1:0];  // signed rep. of partial dout_s for the next cycle

logic signed [Nadc-1:0] dlev; // reference level for ffe adaptation

//logic signed [Nadc+Nint+Nfr-1:0] dlev_fp_expand; // fixed-point rep of dlev
//logic signed [Nint+Nfr-1:0] c_fp[Ntap-1:0]; // fixed-point rep of ffe coef's
//logic signed [Nint+Nfr-1:0] d_cal[Ntap-1:0]; // product of mu*sgn(in)*sgn(err)

real c_fp[Ntap-1:0]; 													// mod by sjkim 
real d_cal[Ntap-1:0]; 													// mod by sjkim 

assign din_aug = {din, din_d[(quo*Nti-1) -: Ntap]};
  
//assign err = (din_aug[Mtap][Nadc-1])? din_aug[Mtap] - dlev : din_aug[Mtap] + dlev;
assign err = (din_aug[Mtap][Nadc-1])? din_aug[Mtap] + dlev : din_aug[Mtap] - dlev;
assign sgn_err = (err[Nadc-1]) ? -1 : +1;
assign i_ffe_coef = c_fp;

generate
  for (k=0;k<Ntap+Nti;k++) 
    assign sgn_d[k] = (din_aug[k][Nadc-1])? -1 : +1;
  for (k=0;k<Ntap;k++)
    //assign d_cal[k] = MU_FP*sgn_d[k]*sgn_err;
    assign d_cal[k] = mu*sgn_d[k]*sgn_err; 										// mod by sjkim
endgenerate

//assign dlev_fp_expand = c_fp[Mtap] << (Nadc-1);
//assign dlev = dlev_fp_expand[(Nadc+Nint+Nfr-1)-:Nadc];
assign dlev = $rtoi(dlev_fp);								// mod by sjkim

always @(posedge clk) begin
  if (~sel_ext) begin
    // shift op
    if (quo == 1) 
      _tmp[Nti-1:0] = din;
    else begin
      for (i=0;i<(quo-1)*Nti;i++) _tmp[i] = din_d[i+Nti];
      _tmp[quo*Nti-1 -: Nti] = din;
    end
    for (i=0;i<quo*Nti;i++) din_d[i] <= _tmp[i];
  end
  else
    din_d <= '{(quo*Nti){0}};
end
real mu_dlev;
assign mu_dlev=mu*10;

// update coefficients
always @(posedge clk or negedge enable) 
  if (!enable) 
    for (int n=0;n<Ntap;n++) 
      //if (n==Mtap) c_fp[n] <= 1 << (Nfr-1);	
      if (n==Mtap) c_fp[n] <= 1;											// mod by sjkim
      else c_fp[n] <= 0;
  else if (!sel_ext) begin
    //for (int n=0;n<Mtap;n++) c_fp[n] <= c_fp[n] + d_cal[n];
    //for (int n=Mtap+1;n<Ntap;n++) c_fp[n] <= c_fp[n] + d_cal[n];
    //c_fp[Mtap] <= c_fp[Mtap] + d_cal[Mtap];
   dlev_fp=dlev_fp+mu_dlev*d_cal[Mtap]/mu*(2**(Nadc-1));
   //for (int n=0;n<Ntap;n++) c_fp[n] <= c_fp[n]+ d_cal[n];								// mod by sjkim
   for (int n=0;n<Ntap;n++) c_fp[n] <= c_fp[n]- d_cal[n];								// mod by sjkim
  end

function signed [Nfr-1:0] to_fpi (input real in);
// convert a real value to an fixed-point integer in Q format
  return 2.0**Nfr*in;
endfunction

//pragma protect end
`endprotect

endmodule

