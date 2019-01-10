/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : ti_adc_top.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Top of TI ADC
  - 

* Note       :
  - Multi-level demultiplexing is ignored at this moment

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module ti_adc_top #(
// parameters here
  parameter integer Nadc = 8,// adc bit width
  parameter integer Nadc_true = 6,								//mod by sjkim
  parameter integer Nti = 1  // total number of slices
) (
// I/Os here
  `input_pwl vin, // differential voltage input
  input clk,  // master clock, full-rate (Nti ==1) or half-rate (Nti !=1)
  output clk_adcout, // clock for retimed data
  output signed [Nadc-1:0] adcout[Nti-1:0], // retimed data
  output [Nti-1:0] dout // data bit stream
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////

//----- SIGNAL DECLARATION -----
genvar k;
logic [Nti-1:0] clk_ti; // multi-phase clocks for Nti-way TI ADCs
logic [Nadc-1:0] dout_slice[Nti-1:0]; // adc output per slice
pwl vrefp, vrefn;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

assign clk_adcout = ~clk_ti[0];

// reference voltage gen
vdc #( .dc(0.5) ) iVREFP ( .vout(vrefp) );
vdc #( .dc(-0.5) ) iVREFN ( .vout(vrefn) );

// ti-adc clock gen
adc_clkgen #( .Nti(Nti) ) iADC_CLKGEN ( .cki(clk), .cko_ti_leaf(clk_ti), .cko_ti_iq() );

// adc slices
//generate 
//  for (k=0;k<Nti;k++) begin: iADCS
  //  adc #( .BITW(Nadc) ) iADCS ( .out_min(vrefn.a), .out_max(vrefp.a), .in(vin), .clk(~clk_ti[k]), .dout(dout_slice[k]), .lsb() );
//    adc_noise #( .BITW(Nadc), .BITW_true(Nadc_true) ) iADCS ( .out_min(vrefn.a), .out_max(vrefp.a), .in(vin), .clk(~clk_ti[k]), .dout(dout_slice[k]), .lsb() );
//    assign dout[k] = adcout[k][Nadc-1] ? 1'b0 : 1'b1;
//  end
//endgenerate

    adc_noise #( .BITW(Nadc), .BITW_true(Nadc_true) ) iADCS ( .out_min(vrefn.a), .out_max(vrefp.a), .in(vin), .clk(~clk_ti[0]), .dout(dout_slice[0]) );
    assign dout[0] = adcout[0][Nadc-1] ? 1'b0 : 1'b1;


// retiming adc to a low-speed clock (Full-rate / Nti)
// This also converts unsigned data to signed one
// this block is unnecessary when (Nti == 1), but I'm lazy :(
ti_adc_retimer #( .Nadc(Nadc), .Nti(Nti) ) iADC_RETIMER ( .clk(clk_adcout), .din(dout_slice), .dout(adcout) );

//pragma protect end
`endprotect

endmodule

