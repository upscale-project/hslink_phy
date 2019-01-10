/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : ffe_bdrate.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: digital Feed-Forward Equalizer (FFE) at Rx
  - FFE tap coefficients are applied to all FFE slices

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module ffe_bdrate #(
// parameters here
  parameter integer Nadc = 8, // adc resolution
  parameter integer Ntap = 1, // number of FFE taps (pre-/post-/main-cursor taps)
  parameter integer Nti  = 1, // total number of slices
  parameter integer Nint = 3, // integer bit width of ffe coefficients
  parameter integer Nfr  = 5  // fractional bit width of ffe coefficients
) (
// I/Os here
  input clk,  // clock
  input bypass, // bypass ffe (act. Hi)
  input signed [Nadc-1:0] din[Nti-1:0],  // data input
  //input signed [Nint+Nfr-1:0] ffe_coef[Ntap-1:0], // ffe taps for each slice (3.Nfr), integer part consists of sign + 1 bit
  real ffe_coef[Ntap-1:0],														// mod by sjkim 
  input [2:0] Ngshl, // dc gain (by 2**Ngshl) where Ngshl >= 0
  input real ffe_scale,
  output logic signed [Nadc-1:0] ffe_out[Nti-1:0], // FFEd data output
  output logic [Nti-1:0] dout // FFEd data bit stream
);


///////////////////
// CODE STARTS HERE
///////////////////

localparam integer quo = $ceil(real'(Ntap)/real'(Nti));
localparam integer Nfo = $clog2(Ntap);  // # of fractional bits in 'ffe_sum' variable

`generate_random_seed(1, 0)

//----- SIGNAL DECLARATION -----
genvar i;
integer j, k;

logic signed [Nadc-1:0] din_d[quo*Nti-1:0];  // signed rep. of partial din for the next cycle
logic signed [Nadc-1:0] din_aug[Nti+Ntap-1:0]; // augment sgn_d for block processing
//logic signed [Nadc+Nfo-1:0] ffe_sum[Nti-1:0]; // FFE sum before bit-slicing to produce outputs
//logic signed [Nadc+Nfo:0] ffe_sum[Nti-1:0]; // FFE sum before bit-slicing to produce outputs
real ffe_sum[Nti-1:0]; // FFE sum before bit-slicing to produce outputs									// mod by sjkim

assign din_aug = {din, din_d[(quo*Nti-1) -: Ntap]}; 

generate 
  for (i=0;i<Nti;i++)
    assign dout[i] = ffe_out[i][Nadc-1] ? 1'b0 : 1'b1;
endgenerate

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin


// shift input data for alignment
logic signed [Nadc-1:0] _tmp[quo*Nti-1:0];
always @(posedge clk or posedge bypass) 
  if (bypass) din_d <= '{(quo*Nti){0}};
  else begin
    // shift op (to right) with resolving X problem
    if (quo == 1) _tmp[Nti-1:0] = din;
    else begin
      for (k=0;k<(quo-1)*Nti;k++) _tmp[k] = din_d[k+Nti];
      _tmp[quo*Nti-1 -: Nti] = din;
    end
    for (k=0;k<quo*Nti;k++) din_d[k] <= replaceX(_tmp[k]);
  end


// summing logic
//logic signed [Nadc+Nint+Nfr:0] _p_ffe_sum;  // term of ffe_sum									// mod by sjkim
always @(*) 
  if (bypass) begin
    for (j=0;j<Nti;j++) 
      //ffe_sum[j] = {din[j], {Nfo{1'b0}}};
      ffe_sum[j] = din[j];														// mod by sjkim
  end
  else begin
    for (j=0;j<Nti;j++) begin // compute a FFEed main cursor value for each slice output
      ffe_sum[j] = 0;
      for (k=0;k<Ntap;k++) begin 
        //_p_ffe_sum = ffe_coef[k]*din_aug[j+k];
        //ffe_sum[j] += _p_ffe_sum[(Nadc+Nfr)-:(Nadc+Nfo-1)];
        ffe_sum[j] += ffe_coef[k]*din_aug[j+k];
      end
    end
  end


// latch output
always @(posedge clk)
  for (j=0;j<Nti;j++) begin
    //ffe_out[j] = ffe_sum[j][(Nadc+Nfo-2)-:Nadc] << Ngshl; // to DFE input
    ffe_out[j] = $rtoi(ffe_sum[j]);			 										// mod by sjkim
  end


function signed [Nadc-1:0] replaceX(input signed [Nadc:0] d);
  if ($isunknown(d)) return $dist_uniform(seed, -2**(Nadc-1), +2**(Nadc-1)-1); // handling initial X's
  else return d;
endfunction

//pragma protect end
`endprotect

endmodule

