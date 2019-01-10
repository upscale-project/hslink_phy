/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : dfe_bdrate.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Digital Decision Feedback Equalizer (DFE) in
  an adc-based link
  - A DFE coefficient is set for each slice data.

* Note       :
  -

* Todo       :
  - Parallel architecture of DFE for faster H/W
  - Handle the case when Ntap > Nti

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module dfe_bdrate #(
// parameters here
  parameter integer Nadc = 8, // adc resolution
  parameter integer Ntap = 1, // number of DFE taps
  parameter integer Nti = 1   // total number of slices
) (
// I/Os here
  input clk,  // clock
  input bypass, // bypass dfe
  input signed [Nadc-1:0] din[Nti-1:0],  // data input
  //input signed [Nadc-1:0] dfe_coef[Nti-1:0][Ntap-1:0], // dfe taps for each slice
  input real dfe_coef[Nti-1:0][Ntap-1:0], 									// mod by sjkim
  output signed [Nadc-1:0] dfe_out[Nti-1:0], // DFEd data output
  output logic [Nti-1:0] dout  // recovered bit-streams of slices
);

`generate_random_seed(1, 0)


///////////////////
// CODE STARTS HERE
///////////////////

localparam integer quo = $ceil(real'(Ntap)/real'(Nti));

//----- SIGNAL DECLARATION -----
integer i, k;
//logic signed [Nadc+Ntap-1:0] dfe_isi[Nti-1:0];  // ISI terms of slices
real dfe_isi[Nti-1:0];  											// mod by sjkim
logic signed [1:0] dout_s[Nti-1:0];  // signed rep. of dout
logic signed [1:0] dout_s_d[quo*Nti-1:0];  // signed rep. of partial dout_s for the next cycle
logic signed [1:0] dout_s_aug[Nti+Ntap-1:0]; // augment dout for block processing

logic signed [1:0] _tmp[quo*Nti-1:0];  // signed rep. of partial dout_s for the next cycle

assign dout_s_aug = {dout_s, dout_s_d[(quo*Nti-1) -: Ntap]};

logic signed [Nadc-1:0] din_scaled[Nti-1:0];  // data input

genvar q;
generate
  for (q=0;q<Nti;q++) 
   // assign din_scaled[q] = (din[q] >>> 1) + (din[q] >>> 2) ;
   assign din_scaled[q] = din[q] ;										// mod by sjkim
endgenerate

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

always @(*) begin // TODO: since the computation is serialized, the H/W will be slow.
  if (bypass) begin
    dfe_out = din_scaled;
    for (k=0;k<Nti;k++) dout_s[k] = dfe_out[k][Nadc-1] ? -1 : +1;
  end
  else begin
    for (k=0;k<Nti;k++) begin // note that how signals traverse
      dfe_isi[k] = 0;
      for (int i=0;i<Ntap;i++) dfe_isi[k] += dfe_coef[k][i]*dout_s_aug[k+Ntap-1-i];
      //dfe_out[k] = din_scaled[k] - dfe_isi[k][Nadc-1:0];
      dfe_out[k] = din_scaled[k] - $rtoi(dfe_isi[k]*2**(Nadc-1));								// mod by sjkim
      dout_s[k] = dfe_out[k][Nadc-1] ? -1 : +1;
    end
  end
end

always @(posedge clk) begin
  // shift op
  if (quo == 1) _tmp[Nti-1:0] = dout_s;
  else begin
    for (i=0;i<(quo-1)*Nti;i++) _tmp[i] = dout_s_d[i+Nti];
    _tmp[quo*Nti-1 -: Nti] = dout_s;
  end
  for (i=0;i<quo*Nti;i++) dout_s_d[i] <= replaceX(_tmp[i]);

  // update dout
  for (i=0;i<Nti;i++) dout[i] <= ~dout_s[i][1];
end

function signed [1:0] replaceX(input signed [1:0] d);
  if ($isunknown(d)) return $dist_uniform(seed, -1, +1); // handling initial X's
  else return d;
endfunction

//pragma protect end
`endprotect


endmodule

