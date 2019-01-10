/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : mm_pd.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: MM phase detector 
  - There are "Nti" # of inputs, which is averaged out.

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module mm_pd #(
// parameters here
  parameter integer Nadc = 8, // adc bit width
  parameter integer Nti = 1,   // total number of slices
  parameter real Bias = 0.0
) (
// I/Os here
  input clk, // adc data clock
  input rstn, // reset (act Lo)
  input signed [Nadc-1:0] din[Nti-1:0],  // adc outputs
  input signed [Nadc-1:0] pd_offset, // add offset ( pd_up + pd_offset/2, pd_dn - pd_offset/2 )
  output logic signed [Nadc-1:0] pd_out, // pd output
  output logic signed [Nadc-1:0] pdu, // pd output
  output logic signed [Nadc-1:0] pdn  // pd output
);

localparam integer Next = $clog2(Nti); // additional bits for adder because of Nti x parallel data


///////////////////
// CODE STARTS HERE
///////////////////
genvar k;

//----- SIGNAL DECLARATION -----
logic signed [Nadc-1:0] xk[Nti:0]; // adc data
logic signed [1:0] ak[Nti:0]; // sliced data
logic signed [Nadc+Next-1:0] out_raw;  // uncompressed output
logic signed [Nadc-1:0] pd_up[Nti-1:0];
logic signed [Nadc-1:0] pd_dn[Nti-1:0];
logic signed [Nadc-1:0] pd_net[Nti-1:0];

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

generate
  for (k=0;k<Nti;k++) begin: uASGN
  //  assign xk[k+1] = din[k];
    assign ak[k] = (xk[k][Nadc-1]==0)? 1 : -1;
    assign pd_up[k] = xk[k]*ak[k+1];
    assign pd_dn[k] = xk[k+1]*ak[k];
    assign pd_net[k] = pd_up[k] - pd_dn[k];
  end
endgenerate

logic signed [Nadc+Next-1:0] tu1, tu2;  // uncompressed output
always @(*) begin
  out_raw = 0;
  tu1 = 0;
  tu2 = 0;
  for (int i=0;i<Nti;i++) begin
    out_raw += pd_net[i];
    tu1 += pd_up[i];
    tu2 += pd_dn[i];
  end
  pdu = tu1/Nti;
  pdn = tu2/Nti;
  pd_out = out_raw / Nti; // average out by Nti
/*
  case (Nti)  // average out by Nti
     1: pd_out = out_raw;
     4: pd_out = out_raw >>> 2;
     8: pd_out = out_raw >>> 3;
    16: pd_out = out_raw >>> 4;
    32: pd_out = out_raw >>> 5;
    64: pd_out = out_raw >>> 6;
    12: pd_out = (out_raw >>> 4) + (out_raw >>> 6) + (out_raw >>> 8) + (out_raw >>> 10); 
    20: pd_out = (out_raw >>> 5) + (out_raw >>> 6) + (out_raw >>> 9) + (out_raw >>> 10); 
    24: pd_out = (out_raw >>> 5) + (out_raw >>> 7) + (out_raw >>> 9); 
    28: pd_out = (out_raw >>> 5) + (out_raw >>> 8); 
  endcase
*/
  pd_out += pd_offset;
end

always @(posedge clk) begin
    xk[0] <= din[Nti-1];
    ak[Nti] <= ak[Nti-1];
    xk[1] <= xk[0];	
end

//pragma protect end
`endprotect

endmodule

