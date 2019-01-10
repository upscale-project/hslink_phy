clear all;
close all;

%%Channel models
model1='../data/peters_01_0605_B12_thru.s4p';
model2='../data/peters_01_0605_B1_thru.s4p';
model3='../data/peters_01_0605_T20_thru.s4p';
model4='../data/Case4_FM_13SI_20_T_D13_L6.s4p';
model5='../data/TEC_Whisper42p8in_Nelco6_THRU_C8C9.s4p';
model6='../data/TEC_Whisper42p8in_Meg6_THRU_C8C9.s4p';

color = ['b','r','g','k','c','m'];


%Channal plots
figure(1)
model_channel(model1,color(1));
%model_channel(model2,color(2));
%model_channel(model3,color(3));
%model_channel(model4,color(4));
%model_channel(model5,color(5));
%model_channel(model6,color(6));



