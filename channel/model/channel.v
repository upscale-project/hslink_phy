/****************************************************************

Copyright (c) 2016-2017 Stanford University. All rights reserved.

The information and source code contained herein is the 
property of Stanford University, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from Stanford University. Contact bclim@stanford.edu for details.

* Filename   : channel.v
* Description: Reduced-order model for measured channel behavior

****************************************************************/

module channel #(
  parameter real etol = 0.001 // error tolerance of PWL approximation
) (
  `input_pwl in, `output_pwl out
);

`get_timeunit
PWLMethod pm=new;

pwl out_arr[0:(26-1)];
pwl out_imm;

complex A0 = '{1.410779316826e+09, 9.497287198304e+08};
complex B0 = '{1.901038116554e+10, -5.960462714710e+10};
pwl_filter_pfe #(.etol(etol)) filter_0(.in(in), .out(out_arr[0]), .A(A0), .B(B0));

complex A1 = '{9.708545929415e+06, 8.039430516270e+06};
complex B1 = '{8.503990037929e+08, -4.792837485851e+10};
pwl_filter_pfe #(.etol(etol)) filter_1(.in(in), .out(out_arr[1]), .A(A1), .B(B1));

complex A2 = '{5.856655071976e+06, 6.752765847407e+06};
complex B2 = '{5.740952364184e+08, -4.115358741098e+10};
pwl_filter_pfe #(.etol(etol)) filter_2(.in(in), .out(out_arr[2]), .A(A2), .B(B2));

complex A3 = '{-3.186049287785e+10, 0.000000000000e+00};
complex B3 = '{2.044541297661e+10, -0.000000000000e+00};
pwl_filter_pfe #(.etol(etol)) filter_3(.in(in), .out(out_arr[3]), .A(A3), .B(B3));

complex A4 = '{-5.753618502249e+07, 2.182571922398e+07};
complex B4 = '{2.233777081393e+09, -3.694155537055e+10};
pwl_filter_pfe #(.etol(etol)) filter_4(.in(in), .out(out_arr[4]), .A(A4), .B(B4));

complex A5 = '{4.183872739857e+06, 7.834805680929e+06};
complex B5 = '{4.234594725748e+08, -3.607907174946e+10};
pwl_filter_pfe #(.etol(etol)) filter_5(.in(in), .out(out_arr[5]), .A(A5), .B(B5));

complex A6 = '{2.891077026729e+10, 0.000000000000e+00};
complex B6 = '{1.297255238905e+10, -0.000000000000e+00};
pwl_filter_pfe #(.etol(etol)) filter_6(.in(in), .out(out_arr[6]), .A(A6), .B(B6));

complex A7 = '{-4.195369843878e+05, -2.620258013207e+06};
complex B7 = '{1.861143593295e+08, -3.357607655027e+10};
pwl_filter_pfe #(.etol(etol)) filter_7(.in(in), .out(out_arr[7]), .A(A7), .B(B7));

complex A8 = '{-6.391981473635e+06, -3.919362251068e+07};
complex B8 = '{7.191630484434e+08, -3.044167888322e+10};
pwl_filter_pfe #(.etol(etol)) filter_8(.in(in), .out(out_arr[8]), .A(A8), .B(B8));

complex A9 = '{-1.839777244225e+07, -1.612660907974e+07};
complex B9 = '{5.188818394930e+08, -2.913333027225e+10};
pwl_filter_pfe #(.etol(etol)) filter_9(.in(in), .out(out_arr[9]), .A(A9), .B(B9));

complex A10 = '{5.642545972055e+08, 0.000000000000e+00};
complex B10 = '{2.445922031851e+09, -0.000000000000e+00};
pwl_filter_pfe #(.etol(etol)) filter_10(.in(in), .out(out_arr[10]), .A(A10), .B(B10));

complex A11 = '{-4.430801606697e+07, -4.883228813837e+07};
complex B11 = '{7.292936819917e+08, -2.747445371917e+10};
pwl_filter_pfe #(.etol(etol)) filter_11(.in(in), .out(out_arr[11]), .A(A11), .B(B11));

complex A12 = '{-2.840732122808e+07, -1.155621341398e+07};
complex B12 = '{4.501101504681e+08, -2.602948165075e+10};
pwl_filter_pfe #(.etol(etol)) filter_12(.in(in), .out(out_arr[12]), .A(A12), .B(B12));

complex A13 = '{-7.249477385357e+07, 1.522143847878e+07};
complex B13 = '{6.762278326290e+08, -2.471694128121e+10};
pwl_filter_pfe #(.etol(etol)) filter_13(.in(in), .out(out_arr[13]), .A(A13), .B(B13));

complex A14 = '{-2.829939589191e+07, -5.875951857594e+06};
complex B14 = '{4.169523206876e+08, -2.294727621691e+10};
pwl_filter_pfe #(.etol(etol)) filter_14(.in(in), .out(out_arr[14]), .A(A14), .B(B14));

complex A15 = '{-4.685925619407e+07, 3.732557284825e+07};
complex B15 = '{5.750197706626e+08, -2.176872165712e+10};
pwl_filter_pfe #(.etol(etol)) filter_15(.in(in), .out(out_arr[15]), .A(A15), .B(B15));

complex A16 = '{-4.630995833462e+07, 6.564593903553e+06};
complex B16 = '{5.811441895937e+08, -2.000490749185e+10};
pwl_filter_pfe #(.etol(etol)) filter_16(.in(in), .out(out_arr[16]), .A(A16), .B(B16));

complex A17 = '{-1.657527857482e+06, 5.319487415714e+07};
complex B17 = '{5.601314197785e+08, -1.901590659995e+10};
pwl_filter_pfe #(.etol(etol)) filter_17(.in(in), .out(out_arr[17]), .A(A17), .B(B17));

complex A18 = '{4.204397320611e+07, 0.000000000000e+00};
complex B18 = '{5.066901020655e+08, -0.000000000000e+00};
pwl_filter_pfe #(.etol(etol)) filter_18(.in(in), .out(out_arr[18]), .A(A18), .B(B18));

complex A19 = '{-2.523392458696e+06, -1.114306273233e+07};
complex B19 = '{3.429543920503e+08, -1.646467670126e+10};
pwl_filter_pfe #(.etol(etol)) filter_19(.in(in), .out(out_arr[19]), .A(A19), .B(B19));

complex A20 = '{-1.681007467517e+07, 8.188825907716e+06};
complex B20 = '{4.086341992345e+08, -1.556929846012e+10};
pwl_filter_pfe #(.etol(etol)) filter_20(.in(in), .out(out_arr[20]), .A(A20), .B(B20));

complex A21 = '{-3.679826579881e+05, 1.571366561238e+06};
complex B21 = '{2.016010808502e+08, -6.217795062637e+09};
pwl_filter_pfe #(.etol(etol)) filter_21(.in(in), .out(out_arr[21]), .A(A21), .B(B21));

complex A22 = '{1.879864372660e+06, 6.265558534571e+05};
complex B22 = '{1.921899602295e+08, -9.766499758436e+09};
pwl_filter_pfe #(.etol(etol)) filter_22(.in(in), .out(out_arr[22]), .A(A22), .B(B22));

complex A23 = '{-1.425597583004e+07, -4.001346869814e+06};
complex B23 = '{4.820418757863e+08, -1.224653761242e+10};
pwl_filter_pfe #(.etol(etol)) filter_23(.in(in), .out(out_arr[23]), .A(A23), .B(B23));

complex A24 = '{4.997425066732e+06, -9.056896029842e+06};
complex B24 = '{3.851309453754e+08, -1.318826963021e+10};
pwl_filter_pfe #(.etol(etol)) filter_24(.in(in), .out(out_arr[24]), .A(A24), .B(B24));

complex A25 = '{2.041585364237e+06, 3.030514072469e+06};
complex B25 = '{3.195263507663e+08, -7.648152781010e+09};
pwl_filter_pfe #(.etol(etol)) filter_25(.in(in), .out(out_arr[25]), .A(A25), .B(B25));
real channel_delay;
real scale[0:(26-1)] = '{1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0};
pwl_add #(.no_sig(26)) add_i(.in(out_arr), .scale(scale), .out(out_imm));

pwl_delay #(.delay(3.922976987654e-09)) delay_i(.in(out_imm), .out(out));
endmodule
