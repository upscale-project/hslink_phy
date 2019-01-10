/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : mm_cdr.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Baud-rate, PI-based CDR with MM PD
  -

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module mm_cdr #(
// parameters here
  parameter integer Nadc = 8, // adc bit width
  parameter integer Nti = 1,  // total number of slices
  parameter integer Nlf = 14, // width of out (Nlf-Npi) is fractional number part
  parameter integer Npi = 8,     // number of PI-bits / UI
  parameter real Kp=0.25,        // proportional gain of PI controller
  parameter integer Ncntr_pd_aux = 8   // counter bit width in aux PD that 
                                       // determines its BW 
) (
// I/Os here
  input [3:0] rclk_iq, // reference I/Q clock inputs
  input clk_data, // parallel data clock
  input signed [Nadc-1:0] din[Nti-1:0],  // adc outputs
  input sel_ext_pi, // set PI control value to "pi_ctl_ext" 
  input [Npi-1:0] pi_ctl_ext, // PI value when sel_ext_pi == Hi
  input sel_ext_pd_offset,  // select "pd_offset_ext" for pd_offset (active Hi)
  input signed [Nadc-1:0] pd_offset_ext,  // externval pd offset value when sel_ext_pd_offset==Hi
  output clk_rcv   // recovered clock to ADC 
);

`get_timeunit

///////////////////
// CODE STARTS HERE
///////////////////
logic signed [Nadc-1:0] pd_offset;

//----- SIGNAL DECLARATION -----

logic rstn_pd;
logic signed [Nadc-1:0] pd_out_0; // pd output
logic signed [Nadc-1:0] pdu_0, pdn_0;
logic [Npi-1:0] pi_ctl;         // PI control output

assign rstn_pd = ~sel_ext_pi;
assign en_pd_aux = ~sel_ext_pd_offset;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

mm_pd #( .Nadc(Nadc), .Nti(Nti), .Bias(0.0) ) iMM_PD ( .clk(clk_data), .rstn(rstn_pd), .din(din), .pd_offset(pd_offset), .pd_out(pd_out_0), .pdu(pdu_0), .pdn(pdn_0) ); // PD

pd_aux #( .Nadc(Nadc), .Nti(Nti), .Ncntr(Ncntr_pd_aux) ) iMM_PD_AUX ( .clk(clk_data), .enable(en_pd_aux), .pd_offset_ext(pd_offset_ext), .din(din), .pd_offset(pd_offset) ); // Auxiliary PD to adjust the main pd offset

dpi_filter #( .Nlf(Nlf), .Nadc(Nadc), .Npi(Npi), .Kp(Kp) ) iFILTER ( .clk(clk_data), .sel_ext(sel_ext_pi), .pi_ctl_ext(pi_ctl_ext), .in(pd_out_0), .out(pi_ctl) ); // Filter

dpi_4quad #( .Nbit(Npi-2), .tdi(1.0/`FULL_RATE+10e-12) ) iPI ( .cki(rclk_iq), .ctl(pi_ctl), .cko(clk_rcv) ); // PI

//pragma protect end
`endprotect

endmodule

