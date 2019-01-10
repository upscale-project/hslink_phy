/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : test.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
	     : Sung-Jin Kim (sjkim85@stanford.edu)
* Description:
  -

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 01/June/18: Initial commit

****************************************************************/

`include "mLingua_pwl.vh"

module test;

`get_timeunit
PWLMethod pm=new;


`define  PI_CODE  480;
parameter integer Nadc = 6;       // ADC bits
parameter integer Nadc_true = 6;        						// mod by sjkim
parameter integer Ntap_ffe = 5;    // # of FFE taps
parameter integer Mtap_ffe = 2;    // Main cursor index (from 0) in FFE
parameter real etol=0.001;


//`define ENABLE_TI // comment this out if a single-ADC (Nti==1) must be configured

`define FULL_RATE 16e9 // full-rate frequency

`ifdef ENABLE_TI
  parameter integer Nti = 4; // total number of slices
  parameter real rx_osc_freq = (`FULL_RATE/2.0);  // half rate osc
`else
  parameter integer Nti = 1; // total number of slices
  parameter real rx_osc_freq = (`FULL_RATE/1.0);  // full rate osc
`endif

parameter integer Npi = 9;         // PI control bits / UI
parameter integer Nint_ffe = 3;    // bit width of integer bit weight (FFE)
parameter integer Nfr_ffe = 12;    // bit width of fractional bit weight (FFE)
parameter integer Ntap_dfe = 1;    // # of DFE taps

parameter real Tstart_hist=2e-6;   // start time for collecting histogram
parameter real Tstart_wave=2e-6;   // start time for saving waveform

//----- SIGNAL DECLARATION -----
logic tx_clk;
logic rstn;
logic tx_prbs;
logic pi_filter_en;
logic dfe_bypass;
logic ffe_bypass;
logic clk_rx_rcv;
logic [Npi-1:0] pi_ctl_ext;
logic [Nti-1:0] data_rx_rcv;
logic sel_ext_pi;
logic [1:0] sel_cdr_din;
logic sel_ext_dfe;
//logic signed [Nadc-1:0] dfe_coef_ext[Nti-1:0][Ntap_dfe-1:0]; 
real dfe_coef_ext[Nti-1:0][Ntap_dfe-1:0];							// mod by sjkim 
logic sel_ext_ffe;
//logic signed [Nint_ffe+Nfr_ffe-1:0] ffe_coef_ext[Ntap_ffe-1:0]; // 0.Nfr_ffe 
real ffe_coef_ext[Ntap_ffe-1:0]; 								// mod by sjkim  
logic sel_ext_pd_offset;
logic signed [Nadc-1:0] pd_offset_ext;

pwl tx_out;
pwl ch_out;
pwl ctle_out;

// initial(external) FFE coefficients setting
initial begin
  for (int i=0;i<Nti;i++)
    for (int j=0;j<Ntap_dfe;j++) 
      if (j==0) dfe_coef_ext[i][j] = 'sd5;
      else dfe_coef_ext[i][j] = 0;

  for (int j=0;j<Ntap_ffe;j++)
    //if (j==0) ffe_coef_ext[j] = to_ffe_fpi(-0.226);  // pre-cursor
    //else if (j==1) ffe_coef_ext[j] = to_ffe_fpi(0.738); // main cursor
    //else if (j==2) ffe_coef_ext[j] = to_ffe_fpi(-0.036); // post-cursor
    if (j==0) ffe_coef_ext[j] = -0.226;  // pre-cursor (mod by sjkim)
    else if (j==1) ffe_coef_ext[j] = 0.738; // main cursor (mod by sjkim)
    else if (j==2) ffe_coef_ext[j] = -0.036; // post-cursor (mod by sjkim)
    else ffe_coef_ext[j] = 0;
end

// convert a real value to an fixed-point integer in Q format
function signed [Nint_ffe+Nfr_ffe-1:0] to_ffe_fpi (input real in);
  return 2.0**(Nfr_ffe)*in;
endfunction



//----- FUNCTIONAL DESCRIPTION -----

parameter real RJrms = 1e-12;		// random clock jitter (mod by sjkim)
parameter real DJmax = 5e-12;		// deterministic clock jitter (mod by sjkim)

// TX reference clock with jitter , reset generation
//clock #( .freq(`FULL_RATE), .td(0) ) iTXCLK ( .ckout(tx_clk) );
clock_jitter #( .freq(`FULL_RATE), .duty(0.5), .RJrms(RJrms), .DJmax(DJmax), .td(0) ) iTXCLK ( .ckout_jitter(tx_clk) ); // mod by sjkim

// test data sequence (PRBS)
prbs21 xprbs ( .clk(tx_clk), .rst(~rstn), .out(tx_prbs) ); 

// TX driver with FFE
tx_driver #( .amp(1.0), .wtap1(-0.2),.wtap0(0.8), .tr(10e-12) ) txdrv (.in(tx_prbs), .clk(tx_clk), .out(tx_out) ); //mod by sjkim
//tx_driver #( .amp(1.0), .wtap1(-0.2),.wtap0(0.8), .tr(10e-12) ) txdrv_test1 (.in(pulse_test), .clk(tx_clk), .out(tx_out_test1) );
//tx_driver #( .amp(1.0), .wtap1(1),.wtap0(0), .tr(10e-12) ) txdrv_test2 (.in(pulse_test), .clk(tx_clk), .out(tx_out_test2) );

// Physical channel mpdel
channel #( .etol(etol) ) xch ( .in(tx_out), .out(ch_out) ); //mod by sjkim
//channel #( .etol(etol) ) xch_test1 ( .in(tx_out_test1), .out(ch_out_test1) );
//channel #( .etol(etol) ) xch_test2 ( .in(tx_out_test2), .out(ch_out_test2) );


// CTLE 
//ctle #(.av(1)) iCTLE ( .in(ch_out), .out(ctle_out) ); //mod by sjkim
//ctle #(.av(1)) iCTLE_test1 ( .in(ch_out_test1), .out(ctle_out_test1) );
//ctle #(.av(1)) iCTLE_test2 ( .in(ch_out_test2), .out(ctle_out_test2) );


// Digital RX
hslink_drx_bdrate #( .Nti(Nti), .Nadc(Nadc), .Nadc_true(Nadc_true), .Npi(Npi), .Nint_ffe(Nint_ffe), .Nfr_ffe(Nfr_ffe), .Ntap_ffe(Ntap_ffe), .Mtap_ffe(Mtap_ffe), .Ntap_dfe(Ntap_dfe), .osc_freq(rx_osc_freq) ) iRX ( .rx_in(ch_out), .sel_cdr_din(sel_cdr_din), .ffe_bypass(ffe_bypass), .dfe_bypass(dfe_bypass), .sel_ext_pi(sel_ext_pi), .pi_ctl_ext(pi_ctl_ext), .sel_ext_dfe(sel_ext_dfe), .dfe_coef_ext(dfe_coef_ext), .sel_ext_ffe(sel_ext_ffe), .ffe_coef_ext(ffe_coef_ext), .sel_ext_pd_offset(sel_ext_pd_offset), .pd_offset_ext(pd_offset_ext), .clk_out(clk_rx_rcv), .dout(data_rx_rcv) );


logic measure_window;			// mod by sjkim
pulse #( .b0(1'b0), .td(Tstart_hist), .tw(1), .tp(2) ) iTSTART (.out(measure_window) ); // mod by sjkim

/*
// monitring signals
logic temp1, temp2;
temp1=0;
temp2=0;
end

assign pulse_test = temp1 & ~temp2;

always @(posedge tx_clk & measure_window) begin
temp1 <=1;
temp2 <= temp1;
end

pwl tx_out_test1,tx_out_test2,ch_out_test1,ch_out_test2, ctle_out_test1, ctle_out_test2;
real tx_out_test1_r,tx_out_test2_r,ch_out_test1_r,ch_out_test2_r,ctle_out_test1_r, ctle_out_test2_r;
assign tx_out_test1_r = tx_out_test1.a;
assign tx_out_test2_r = tx_out_test2.a;
assign ch_out_test1_r = ch_out_test1.a;
assign ch_out_test2_r = ch_out_test2.a;
assign ctle_out_test1_r = ctle_out_test1.a;
assign ctle_out_test2_r = ctle_out_test2.a;
*/


pulse #( .td(1e-9), .tw(1), .tp(2) ) iRSTN (.out(rstn) ); // reset generation

// FFE control
pulse #( .b0(1'b1), .td(120e-9), .tw(1), .tp(2) ) iFFEBYPASS (.out(ffe_bypass) ); //  bypass FFE (act. Hi)
pulse #( .b0(1'b1), .td(140e-9), .tw(1), .tp(2) ) iFFESELEXT (.out(sel_ext_ffe) ); // select external FFE coefficients (act. Hi)
// DFE control
pulse #( .b0(1'b1), .td(100e-9), .tw(1), .tp(2) ) iDFEBYPASS (.out(dfe_bypass) ); // bypass DFE (act. Hi)
pulse #( .b0(1'b1), .td(110e-9), .tw(1), .tp(2) ) iDFESELEXT (.out(sel_ext_dfe) ); // select external DFE coefficients (act. Hi)

// CDR control


// PI control
//pulse #( .b0(1'b1), .td(200e-9), .tw(1), .tp(2) ) iPIFILTEREN (.out(sel_ext_pi) ); // select external PI values (act. Hi)
bitvector #( .bit_width(1), .value(1) ) iPFILTEREN ( .out(sel_ext_pi) ); // external PI control value when sel_ext_pi = Hi
bitvector #( .bit_width(Npi), .value(`PI_CODE) ) iPIEXTCTL ( .out(pi_ctl_ext) ); // (w/ CTLE)

  // MM-PD control
bitvector #( .bit_width(2), .value(0) ) iSELCDRDIN ( .out(sel_cdr_din) ); // select data to CDR
pulse #( .b0(1'b0), .td(50e-6), .tw(1), .tp(2) ) iSELEXTPDOFFSET (.out(sel_ext_pd_offset) ); // select external PD offset value (act. Hi)
                                                                                             // setting this Low enables auxiliary PD
//bitvector #( .bit_width(Nadc), .value(-35) ) iPDOFFSET ( .out(pd_offset_ext) );              // PD offset value when sel_ext_pd_offset = Hi
bitvector #( .bit_width(Nadc), .value(-40) ) iPDOFFSET ( .out(pd_offset_ext) );              // PD offset value when sel_ext_pd_offset = Hi



/*
pwl rclk_rcv;
bit2pwl #( .vh(0.5), .vl(-0.5), .tr(10e-12), .tf(10e-12) ) iB2P ( .in(iRX.clk_rcv), .out(rclk_rcv) );
//pwl_probe #( .Tstart(Tstart_wave), .Tend(1), .filename("tx_out.txt") ) iPROBE_3 ( .in(tx_out) );
pwl_probe #( .Tstart(Tstart_wave), .Tend(1), .filename("clk_rcv.txt") ) iPROBE_2 ( .in(rclk_rcv) );
pwl_probe #( .Tstart(Tstart_wave), .Tend(1), .filename("ctle_out.txt") ) iPROBE_1 ( .in(ctle_out) );
pwl_probe #( .Tstart(Tstart_wave), .Tend(1), .filename("ch_out.txt") ) iPROBE_0 ( .in(ch_out) );
*/




////////////////
// probe signals
////////////////
/*

logic [Nadc-1:0] adc_out, ffe_out, dfe_out;
logic [Nint_ffe+Nfr_ffe-1:0] ffe_c[Ntap_ffe];
logic sample_clk;
always @(clk_rx_rcv) sample_clk <= #1 clk_rx_rcv;
always @(posedge sample_clk) begin
  adc_out <= iRX.data_adc[0];
  ffe_out <= iRX.ffe_out[0];
  dfe_out <= iRX.dfe_out[0];
  ffe_c[0] <= iRX.ffe_coef[0];
  ffe_c[1] <= iRX.ffe_coef[1];
  ffe_c[2] <= iRX.ffe_coef[2];
  ffe_c[3] <= iRX.ffe_coef[3];
  ffe_c[4] <= iRX.ffe_coef[4];
end
*/
real tx_out_r, ch_out_r, ctle_out_r;
assign tx_out_r = tx_out.a;
assign ch_out_r = ch_out.a;
assign ctle_out_r = ctle_out.a;
initial begin
  $shm_open("sim.shm");
  $shm_probe(test.tx_clk);
  $shm_probe(test.tx_out_r);
  $shm_probe(test.ch_out_r);
  $shm_probe(test.ctle_out_r);
  
  $shm_probe(test.iRX.data_adc, test.iRX.ffe_out, test.iRX.dfe_out);
  $shm_probe(test.iRX.ffe_coef);
  $shm_probe(test.iRX.dfe_coef);
  $shm_probe(test.iRX.iFFE_ADAPT.dlev);
  $shm_probe(test.iRX.iDFE_ADAPT.dlev);
  $shm_probe(test.iRX.iFFE_ADAPT.err);
  $shm_probe(test.iRX.iDFE_ADAPT.err);
  $shm_probe(test.iRX.dout_ffe);
  $shm_probe(test.iRX.dout);
  $shm_probe(test.tx_prbs);
  //$shm_probe(test.pulse_test);
  //$shm_probe(test.tx_out_test1_r);
  //$shm_probe(test.tx_out_test2_r);
  //$shm_probe(test.ch_out_test1_r);
  //$shm_probe(test.ch_out_test2_r);
  //$shm_probe(test.ctle_out_test1_r);
  //$shm_probe(test.ctle_out_test2_r);
  $shm_probe(test.iRX.clk_rcv);
//  $shm_probe(test.iRX.iADC_TOP.iADCS, "A");
//  $shm_probe(test.iTXCLK, "A");
  $shm_probe(test.iRX.iMM_CDR.pi_ctl);
  $shm_probe(test.iRX.iMM_CDR.iMM_PD.pd_offset);
  $shm_probe(test.iRX.iMM_CDR,"A");
  //$shm_probe(test.iRX.iMM_CDR.iMM_PD_AUX.pd_offset_fp);
  //$shm_probe(test.iRX.iMM_CDR.iMM_PD_AUX.pd_diff_1_2_abs_prev);
  //$shm_probe(test.iRX.iMM_CDR.iMM_PD_AUX.pd_diff_1_2);
  $shm_probe(test.iRX.iMM_CDR.iMM_PD_AUX,"A");
  $shm_probe(test.sel_ext_pd_offset);
end


//////////////////////
// Measuring Histogram
//////////////////////

integer signed adc_out, ffe_out, dfe_out;
integer fid0, fid1, fid2, fid3;
initial begin
 //fid0 = $fopen("./dump_out/tx_prbs.txt","w");
 fid1 = $fopen($sformatf("./adc_out_%0d.txt",`PI_CODE),"w");
 fid2 = $fopen($sformatf("./ffe_out_%0d.txt",`PI_CODE),"w");
 fid3 = $fopen($sformatf("./dfe_out_%0d.txt",`PI_CODE),"w");
 assign adc_out= test.iRX.data_adc[0];
 assign ffe_out= test.iRX.ffe_out[0];
 assign dfe_out= test.iRX.dfe_out[0];
end

always @(posedge tx_clk & measure_window) begin
$fwrite(fid0, "%d\n", tx_prbs);
end

always @(posedge clk_rx_rcv & measure_window) begin
$fwrite(fid1, "%d\n", adc_out);
$fwrite(fid2, "%d\n", ffe_out);
$fwrite(fid3, "%d\n", dfe_out);
end

// simultion control
initial
  $timeformat(-9,3," [usec]",20);
always #(1e-6*1s)
  $display("Simulation runs at %t", $realtime/1000);


endmodule

