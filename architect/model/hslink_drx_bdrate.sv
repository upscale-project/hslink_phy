/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : hslink_drx_bdrate.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: High-speed link receiver 
  - Baud-rate CDR
  - Time-interleaved ADC-based digital receiver

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module hslink_drx_bdrate #(
// parameters here
  parameter integer Nti = 1,    // total number of slices
  parameter integer Nadc = 8,        // ADC bits
  parameter integer Nadc_true = 6,        									// mod by sjkim
  parameter integer Npi = 7,    // PI control bits / UI
  parameter integer Nint_ffe = 3, // bit width of integer bit weight (FFE)
  parameter integer Nfr_ffe = 10, // bit width of fractional bit weight (FFE)
  parameter integer Ntap_ffe = 3,        // # of FFE taps
  parameter integer Mtap_ffe = 1,        // Main cursor location in FFE
  parameter integer Ntap_dfe = 1,        // # of DFE taps
  parameter real osc_freq = 1e9 // half rate osc
) (
// I/Os here
  `input_pwl rx_in, // receiver input 
  input [1:0] sel_cdr_din,  // select feedback data input to MM PD
                            // '00': from ADC, '01': from FFE, '10'/'11': from DFE
  input ffe_bypass, // bypass ffe (active Hi)
  input dfe_bypass, // bypass dfe (active Hi)
  input sel_ext_pi, // select external pi value
  input [Npi-1:0] pi_ctl_ext, // pi_ctl value when sel_ext_pi == Hi
  input sel_ext_dfe,  // select external dfe coefs (act. Hi)
  //input signed [Nadc-1:0] dfe_coef_ext[Nti-1:0][Ntap_dfe-1:0], // external dfe taps for each slice
  input real dfe_coef_ext[Nti-1:0][Ntap_dfe-1:0], 								// mod by sjkim
  input sel_ext_ffe,  // select external ffe coefs (act. Hi)
  //input signed [Nint_ffe+Nfr_ffe-1:0] ffe_coef_ext[Ntap_ffe-1:0], // external ffe taps for all slices
  input real ffe_coef_ext[Ntap_ffe-1:0], 									// mod by sjkim
  input sel_ext_pd_offset,  // select "pd_offset_ext" for pd_offset (active Hi)
  input signed [Nadc-1:0] pd_offset_ext,  // externval pd offset value when sel_ext_pd_offset==Hi
  output clk_out,   // clock for retiming adc data
  output [Nti-1:0] dout   // recovered bit-streams of slices
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////


// PI
localparam integer Nlf = (Npi+10);  // bit width of PI loop filter
localparam real Kp_PI=0.001*2**(Npi-7); // proportional gain of PI controller
localparam integer Ncntr_pd_aux = 16-$clog2(Nti);  // counter bit width in aux PD that determines its BW 
                                       // This number depends on the number of samples (and thus Nti)

// OSC
localparam real etol_phase = 0.01;  // phase error tolerance in [rad]

// CTLE
localparam real etol_ctle =0.01; // error tolerance of PWL approximation
//localparam real av_ctle   = 1.0;   // dc gain
//localparam real fz1_ctle  = 550e6; // zero in Hz
//localparam real fp1_ctle  = 1.2e9; // 1st pole in Hz
//localparam real fp2_ctle  = 3.4e9;   // 2nd pole in Hz
// 8gbps
//localparam real av_ctle   = 1.2;   // dc gain
//localparam real fz1_ctle  = 550e6; // zero in Hz
//localparam real fp1_ctle  = 2*1.2e9; // 1st pole in Hz
//localparam real fp2_ctle  = 2*2.5e9;   // 2nd pole in Hz
// 16gbps
localparam real av_ctle   = 1.0;   // dc gain
localparam real fz1_ctle  = 550e6; // zero in Hz
localparam real fp1_ctle  = 2*1.5e9; // 1st pole in Hz
localparam real fp2_ctle  = 2*3.0e9;   // 2nd pole in Hz


// FFE, DFE
localparam real mu_ffe = 1.0/2**(Nfr_ffe-1)/10;  // dv of adaptation adjustment ( mu >= 1.0/2^FP_Q)
localparam integer Nfr_dfe = 10; // bit width of fractional bit of mu (DFE)
localparam real mu_dfe = 0.0001/10;  // dv of adaptation adjustment ( mu >= 1.0/2^FP_Q)


//----- SIGNAL DECLARATION -----
pwl ONE = `PWL1;
pwl ZERO = `PWL0;
pwl ctle_out;

logic dfe_en; // enable dfe (act Hi)
logic ffe_en; // enable ffe (act Hi)
logic [3:0] rclk_iq;  // reference I-Q clocks for CDR
logic signed [Nadc-1:0] data_adc[Nti-1:0]; // retimed, parallel adc data output
//logic signed [Nadc-1:0] dfe_coef[Nti-1:0][Ntap_dfe-1:0]; // dfe taps for each slice
real dfe_coef[Nti-1:0][Ntap_dfe-1:0]; 											// mod by sjkim
logic signed [Nadc-1:0] dfe_out[Nti-1:0]; // DFEd data output
logic signed [Nadc-1:0] cdr_din[Nti-1:0]; // retimed, parallel adc data output
logic clk_rcv;   // recovered rx clock, probe purpose
logic clk_adc;   // clock

logic [2:0] Ngshl_ffe;
logic signed [Nadc-1:0] ffe_out[Nti-1:0]; // FFEd data output
//logic signed [Nint_ffe+Nfr_ffe-1:0] ffe_coef[Ntap_ffe-1:0]; // ffe taps for each slice
real ffe_coef[Ntap_ffe-1:0]; 												// mod by sjkim

logic [Nti-1:0] dout_adc; // ADC data bit stream
logic [Nti-1:0] dout_ffe; // FFEd data bit stream

assign clk_out = clk_adc;
assign dfe_en = ~dfe_bypass;
assign ffe_en = ~ffe_bypass;

assign Ngshl_ffe = 0;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

// odt
assign cdr_din = (sel_cdr_din==2'b00) ? data_adc : (sel_cdr_din==2'b01) ? ffe_out : dfe_out ;

// ctle
//ctle #( .etol(etol_ctle), .av(av_ctle), .fz1(fz1_ctle), .fp1(fp1_ctle), .fp2(fp2_ctle) ) iCTLE ( .in(rx_in), .out(ctle_out) );

// adc
//ti_adc_top #( .Nadc(Nadc), .Nti(Nti) ) iADC_TOP ( .vin(ctle_out), .clk(clk_rcv), .clk_adcout(clk_adc), .adcout(data_adc), .dout(dout_adc) );
ti_adc_top #( .Nadc(Nadc), .Nadc_true(Nadc_true), .Nti(Nti) ) iADC_TOP ( .vin(rx_in), .clk(clk_rcv), .clk_adcout(clk_adc), .adcout(data_adc), .dout(dout_adc) );

// ffe
ffe_bdrate #( .Nadc(Nadc), .Nint(Nint_ffe), .Nfr(Nfr_ffe), .Ntap(Ntap_ffe), .Mtap(Mtap_ffe), .Nti(Nti) ) iFFE ( .clk(clk_adc), .bypass(ffe_bypass), .din(data_adc), .ffe_coef(ffe_coef), .Ngshl(Ngshl_ffe), .ffe_out(ffe_out), .dout(dout_ffe) ); // ffe core

ffe_adaptation_bdrate #( .Nadc(Nadc), .Ntap(Ntap_ffe), .Mtap(Mtap_ffe), .Nti(Nti), .Nint(Nint_ffe), .Nfr(Nfr_ffe), .mu(mu_ffe) ) iFFE_ADAPT ( .clk(clk_adc), .enable(ffe_en), .din(ffe_out), .sel_ext(sel_ext_ffe), .ffe_coef_ext(ffe_coef_ext), .ffe_coef(ffe_coef) ); // dfe adaptation 

// dfe
dfe_bdrate #( .Nadc(Nadc), .Ntap(Ntap_dfe), .Nti(Nti) ) iDFE ( .clk(clk_adc), .bypass(dfe_bypass), .din(ffe_out), .dfe_coef(dfe_coef), .dfe_out(dfe_out), .dout(dout) ); // dfe core

dfe_adaptation_bdrate #( .Nadc(Nadc), .Ntap(Ntap_dfe), .Nti(Nti), .Nfr(Nfr_dfe), .mu(mu_dfe) ) iDFE_ADAPT ( .clk(clk_adc), .enable(dfe_en), .din(dfe_out), .sel_ext(sel_ext_dfe), .dfe_coef_ext(dfe_coef_ext), .dfe_coef(dfe_coef) ); // dfe adaptation 

// cdr
mm_cdr #( .Nadc(Nadc), .Nti(Nti), .Nlf(Nlf), .Npi(Npi), .Kp(Kp_PI), .Ncntr_pd_aux(Ncntr_pd_aux) ) iMM_CDR ( .rclk_iq(rclk_iq), .clk_data(clk_adc), .din(cdr_din), .sel_ext_pi(sel_ext_pi), .pi_ctl_ext(pi_ctl_ext), .sel_ext_pd_offset(sel_ext_pd_offset), .pd_offset_ext(pd_offset_ext), .clk_rcv(clk_rcv) );

// oscillator
// reference clock will be provided externally for this block in the future
osc_4ph #( .freq(osc_freq), .etol_phase(0.01) ) iOSC_IQ ( .cko(rclk_iq) );


//pragma protect end
`endprotect

endmodule

