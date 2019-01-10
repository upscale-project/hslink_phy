%
% Copyright (c) 2017 Stanford University. All rights reserved.
% 
% The information and source code contained herein is the 
% property of Stanford University, and may not be disclosed or
% reproduced in whole or in part without explicit written 
% authorization from Stanford University. Contact bclim@stanford.edu for details.
%
% Filename   : model_channel.m
% Description: Determines channel model from S parameters and writes it to file.
%

function model_channel(fname, color)

    % Read S-parameters from file
    
    sparams = sparameters(fname);
    data = sparams.Parameters;
    freq = sparams.Frequencies;
    z0 = sparams.Impedance;
    
    % Determine transfer functions
    H = s2tf(s2sdd(data), 2*z0, 2*z0, 2*z0);
    
    % Fit rational function
    delayFactor = 0.98;
    rfunc = rationalfit(freq, H, 'DelayFactor', delayFactor);
    
    % write to file
    fid = fopen('sys.txt', 'w');
    fprintf(fid, '%0.12e\n', rfunc.Delay);
    
    % write the A coefficients in real-imaginary form
    A = [real(rfunc.A)'; imag(rfunc.A)'];
    fprintf(fid, '%0.12e ', A(:));
    fprintf(fid, '\n');
    
    % write the C coefficients in real-imaginary form
    C = [real(rfunc.C)'; imag(rfunc.C)'];
    fprintf(fid, '%0.12e ', C(:));
    fprintf(fid, '\n');
    
    fclose(fid);
    
    % write frequency response to file
    fid = fopen('fft.txt', 'w');
    fprintf(fid, '%d\n', length(freq));
    for k=1:length(freq)
        fprintf(fid, '%0.12e ', freq(k));
        fprintf(fid, '%0.12e ', real(H(k)));
        fprintf(fid, '%0.12e ', imag(H(k)));
        fprintf(fid, '\n');
    end
    
    fclose(fid);

	mag=sqrt(real(H).^2+imag(H).^2);
	mag_db=20*log10(mag);

%	semilogx(freq/1e9,mag_db,color,'LineWidth',2);xlabel('Freq(GHz)');ylabel('loss(dB)');grid on;hold on;axis([0.1 15 -60 0]);
%	plot(freq/1e9,mag_db,color,'LineWidth',2);xlabel('Freq(GHz)');ylabel('loss(dB)');grid on;hold on;axis([0.1 15 -60 0]);

%% CTLE
% Fz=800e6;
% Fp1=4e9;
% Fp2=5e9;
% Wz=2*pi*Fz;
% Wp1=2*pi*Fp1;
% Wp2=2*pi*Fp2;
% W=2*pi*freq;
% 
% K=Wp1*Wp2/Wz;
% A=-1*Wz;
% B=W;
% C=Wp1*Wp2-W.^2;
% D=-1*(Wp1+Wp2)*W;
% 
% mag_ctle=K*sqrt((A*C+B.*D).^2+(B.*C-A*D).^2)./(C.^2+D.^2);
% mag_ctle_db=20*log10(mag_ctle);
% semilogx(freq/1e9,mag_ctle_db,'k','LineWidth',2);
% 
% channel_w_ctle=mag_db+mag_ctle_db;
% semilogx(freq/1e9,channel_w_ctle,'r','LineWidth',2);

end
