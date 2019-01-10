/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : dfe_adaptation_bdrate.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Adaptation logic for a baud-rate digital DFE
  - This is sign-sign LMS adaptation
  - per-slice adaptation which might be useful for canceling out
    mismatches between slices.

* Note       :
  - To disable DFE, one can drive 0 values of DFE coefficients 
    externally and select them by setting sel_ext == Hi

* Todo       :
  - Handle the case when Ntap > Nti

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dfe_adaptation_bdrate #(
// parameters here
  parameter integer Nadc = 8, // adc resolution
  parameter integer Ntap = 1, // number of DFE taps
  parameter integer Nti = 1,  // total number of slices
  parameter integer Nfr = 10, // bit width of fractional bit of mu
  parameter real mu = 0.008   // dv of adaptation adjustment ( mu >= 1.0/2^FP_Q)
) (
// I/Os here
  input clk,  // clock
  input enable, // enable (active Hi)
  input signed [Nadc-1:0] din[Nti-1:0],  // data input
  input sel_ext,  // select dfe_coefficient (Hi: external value, Lo: value from this adaptation logic)
  //input signed [Nadc-1:0] dfe_coef_ext[Nti-1:0][Ntap-1:0], // external dfe coef's for each slice
  //output signed [Nadc-1:0] dfe_coef[Nti-1:0][Ntap-1:0]  // external dfe coef's for each slice
  input real dfe_coef_ext[Nti-1:0][Ntap-1:0], 									// mod by sjkim
  output real dfe_coef[Nti-1:0][Ntap-1:0]  									// mod by sjkim 
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////
// localparam signed [Nfr-1:0] MU_FP = to_fpi(mu);  // fixed-point representation of "mu" parameter		// mod by sjkim
localparam integer quo = $ceil(real'(Ntap)/real'(Nti));

genvar j, k;
integer i;

//----- SIGNAL DECLARATION -----

//logic signed [Nadc-1:0] i_dfe_coef[Nti-1:0][Ntap-1:0]; // external dfe coef's for each slice
real i_dfe_coef[Nti-1:0][Ntap-1:0]; 										// mod by sjkim

assign dfe_coef = sel_ext ? dfe_coef_ext : i_dfe_coef;  // select dfe coefficients

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

logic signed [Nadc-1:0] err[Nti-1:0];  // error signal of input
logic signed [1:0] sgn_err[Nti-1:0];  // sign of error signal
logic signed [1:0] sgn_err_d[quo*Nti-1:0];  // signed rep. of partial sng_err for the next cycle
logic signed [1:0] sgn_err_aug[Nti+Ntap-1:0]; // augment sgn_err for block processing
logic signed [1:0] sgn_d[Nti-1:0];
logic signed [1:0] sgn_d_d[quo*Nti-1:0];  // signed rep. of partial sng_d for the next cycle
logic signed [1:0] sgn_d_aug[Nti+Ntap-1:0]; // augment sgn_d for block processing

logic signed [1:0] _tmp[quo*Nti-1:0];  // signed rep. of partial dout_s for the next cycle

logic signed [Nadc-1:0] dlev[Nti-1:0]; // reference level for dfe adaptation
//logic signed [Nadc+Nfr-1:0] dlev_fp[Nti-1:0]; // fixed-point rep of dlev
//logic signed [Nadc+Nfr-1:0] c_fp[Nti-1:0][Ntap-1:0]; // fixed-point rep of dfe coef's
//logic signed [Nadc+Nfr-1:0] d_cal[Nti-1:0][Ntap:0]; // product of mu*sgn(in)*sgn(err)

real dlev_fp[Nti-1:0];										// mod by sjkim 
real c_fp[Nti-1:0][Ntap-1:0]; 									// mod by sjkim
real d_cal[Nti-1:0][Ntap:0]; 									// mod by sjkim

assign sgn_d_aug = {sgn_d, sgn_d_d[(quo*Nti-1) -: Ntap]};
assign sgn_err_aug = {sgn_err, sgn_err_d[(quo*Nti-1) -: Ntap]};

generate
  for (j=0;j<Nti;j++) begin: uASGN0
    assign sgn_d[j] = (din[j][Nadc-1])? -1 : +1;
    assign err[j] = (din[j][Nadc-1])? din[j] + dlev[j] : din[j] - dlev[j];
    assign sgn_err[j] = (err[j][Nadc-1])? -1 : +1;
    for (k=0;k<Ntap+1;k++) begin: uASGN1
      //assign d_cal[j][k] = MU_FP*sgn_d_aug[Ntap+j-k]*sgn_err_aug[Ntap+j];			
      assign d_cal[j][k] = mu*sgn_d_aug[Ntap+j-k]*sgn_err_aug[Ntap+j];			// mod by sjkim
    end
    //assign dlev[j] = dlev_fp[j][(Nadc+Nfr-1)-:Nadc];
    assign dlev[j] = $rtoi(dlev_fp[j]);							// mod by sjkim
    for (k=0;k<Ntap;k++) begin: uASGN2
      //assign i_dfe_coef[j][k] = c_fp[j][k][(Nadc+Nfr-1)-:Nadc];
      assign i_dfe_coef[j][k] = c_fp[j][k];						// mod by sjkim
    end
  end
endgenerate

real mu_dlev;										// mod by sjkim
assign mu_dlev=mu*10;									// mod by sjkim


always @(posedge clk) begin
  if (~sel_ext) begin
    // shift op
    if (quo == 1) _tmp[Nti-1:0] = sgn_d;
    else begin
    	for (i=0;i<(quo-1)*Nti;i++) _tmp[i] = sgn_d_d[i+Nti];
      	_tmp[quo*Nti-1 -: Nti] = sgn_d;
    	end
    	for (i=0;i<quo*Nti;i++) sgn_d_d[i] <= _tmp[i];
    
    if (quo == 1) _tmp[Nti-1:0] = sgn_err;
    else begin
    	for (i=0;i<(quo-1)*Nti;i++) _tmp[i] = sgn_err_d[i+Nti];
    	_tmp[quo*Nti-1 -: Nti] = sgn_err;
    	end
    	for (i=0;i<quo*Nti;i++) sgn_err_d[i] <= _tmp[i];
  end
  else begin
    sgn_d_d <= '{(quo*Nti){0}};
    sgn_err_d <= '{(quo*Nti){0}};
  end
end

always @(posedge clk or negedge enable) begin
  if (!enable) begin
    for (int m=0;m<Nti;m++) begin
      dlev_fp[m] <= 0;
      for (int n=0;n<Ntap;n++) c_fp[m][n] <= 0;
    end
  end
  else if (!sel_ext) begin
    for (int m=0;m<Nti;m++) begin
      dlev_fp[m] <= dlev_fp[m] + (mu_dlev*d_cal[m][0]/mu*2**(Nadc-1));
      for (int n=0;n<Ntap;n++) c_fp[m][n] <= c_fp[m][n] + d_cal[m][n+1];
    end
  end
  else begin
    dlev_fp <= '{(Nti){'0}};								// mod by sjkim
    c_fp <= '{(Nti){'{(Ntap){'0}}}};
    //dlev_fp <= 0;									// mod by sjkim
    //c_fp <= 0;
  end
end 

function signed [Nfr-1:0] to_fpi (input real in);
// convert a real value to an fixed-point integer in Q format
  return 2.0**Nfr*in;
endfunction

//pragma protect end
`endprotect

endmodule

