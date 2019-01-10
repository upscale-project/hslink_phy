/******************************************************************
Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#.

* Filename   : pd_aux.v
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Auxiliary PD to maximize ADC SNR
  - Calibrate the amount of phase offset injected to the main PD

* Note       :
  -

* Todo       :
  -

* Revision   :
  - 00/00/00: Initial commit

****************************************************************/


module pd_aux #(
// parameters here
  parameter integer Nadc = 8, 			 // ADC bits
  parameter integer Nti = 1,  			 // total number of slices
  parameter integer Ncntr = 8, 			 // counter bit width for windowing data
	parameter integer Nc_invalid = (Ncntr-5)  // wait for 2**(Nc-1) cycles to be settled
) (
// I/Os here
  input clk, // parallel data clock
  input enable, // enable this auxiliary pd (active Hi)
  input signed [Nadc-1:0] din[Nti-1:0],  // data inputs to PD
  input signed [Nadc-1:0] pd_offset_ext,  // external value for pd_offset (valid when enable == Lo)
  output logic signed [Nadc-1:0] pd_offset  // main pd offset
);

`get_timeunit
PWLMethod pm=new;


///////////////////
// CODE STARTS HERE
///////////////////
localparam integer Nfr = 1;	// bit width of fraction part in pd_offset_fp
localparam integer dy0 = 1;	// step size of dy for computing threshold

genvar k;

initial // assert on parameters
  assert (Ncntr > Nc_invalid) else $error( "%m: Ncntr(%d) must be larger than Nc_invalid(%d) !!!", Ncntr, Nc_invalid);

//----- SIGNAL DECLARATION -----
logic startup;  // to ignore the first comparison after enabled
logic pd_dir; // pd offset direction; Hi: increment, Lo: decrement
logic [Ncntr-1:0] cntr; // counter for resetting accumulator for refresh
logic signed [Nadc+Nfr-1:0] pd_offset_fp;  // main pd offset in FP

logic [Nadc-1:0] d_min, d_min_prev;
logic [Nadc-1:0] _d_min;
logic [Nadc-1:0] abs_din[Nti];
logic [Nadc-1:0] threshold;

logic [Nadc+Ncntr+$clog2(2*Nti)-1:0] no_err, no_err_prev;
logic [$clog2(2*Nti)-1:0] inc;  // increment per clock
logic [Nadc-1:0] dy;

assign pd_offset = pd_offset_fp[Nadc+Nfr-1 -: Nadc]; // take int part
assign threshold = d_min_prev+dy;

//----- FUNCTIONAL DESCRIPTION -----
`protect
//pragma protect 
//pragma protect begin

generate // absolute value of din
  for (k=0;k<Nti;k++) 
    assign abs_din[k] = (din[k][Nadc-1])? ~din[k] + 1 : din[k];
endgenerate

always @(*) begin // find # of errors 
  inc = 0;
  for (int i=0;i<Nti;i++) begin
    if (abs_din[i] < threshold) inc += 1;
  end
end

always @(*) begin // find min
  _d_min = d_min;
  for (int i=0;i<Nti;i++) 
    if (abs_din[i] < _d_min) _d_min = abs_din[i];
end

always @(posedge clk or negedge enable) // reference counter
  if (!enable) cntr <= 0;
  else cntr <= cntr + 1;

always @(posedge clk or negedge enable) // update min(din) and count # of error
  if (!enable) begin
    no_err <= '1;  
    d_min <= 2**Nadc -1;
  end
  else if (cntr==0) begin
    no_err <= 0;
    d_min <= 2**Nadc -1;
  end
  else if (cntr >= {(Nc_invalid){1'b1}}) begin // update minimum data value
    no_err <= no_err + inc;
    d_min <= _d_min;
  end

always @(posedge clk or negedge enable) // update pd_offset
  if (!enable) begin
    pd_offset_fp <= pd_offset_ext << Nfr;
    pd_dir <= 1'b1;
    no_err_prev <= 0; 
    startup <= 1'b1;
    d_min_prev <= 2**Nadc - 1;
    dy <= dy0;
  end
  else 
    if (cntr=='1) begin // update pd_offset
      if (startup) begin
        startup <= 0;
        no_err_prev <= no_err;
				d_min_prev <= d_min;
      end
      else begin
        if (no_err > no_err_prev) begin // error was increased, change direction
          dy <= dy0;
          pd_offset_fp <= pd_offset_fp + ( pd_dir ? -1 : +1 ); 
          pd_dir <= ~pd_dir;
	  			d_min_prev <= d_min;
          no_err_prev <= no_err;
        end
        else begin  // error was decreased, keep the direction
          if (no_err == 0) begin	// increase threshold 
            pd_offset_fp <= pd_offset_fp + ( pd_dir ? +1 : -1 );
            dy <= dy + dy0;
            no_err_prev <= '1;
          end
          else begin
            pd_offset_fp <= pd_offset_fp + ( pd_dir ? +2 : -2 );
            no_err_prev <= no_err;
          end
        end
      end
    end

//pragma protect end
`endprotect

endmodule

