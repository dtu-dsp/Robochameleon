% This runs setup_16QAM.m, a back-to-back 16QAM setup
%
% setup_16QAM.m is a 16QAM transmitter/receiver with the simplest 
% possible configuration.

%Add folders to path
robochameleon

clc
clear
close all
close_biographs

%specify parameters
param.qam16.prbsSize = 15;
param.qam16.total_length = 2^16;
param.qam16.Rs = 10e9;
param.qam16.delayPAM = 325;
param.qam16.delayQAM = 101;

param.SNR.SNR = 15;
param.SNR.M = 16;

param.bert.M=16;
param.bert.prbs = gen_prbs(15);
param.bert.margin = [1e3 0];

%construct system and run simulation
mytest=setup_16QAM(param);
mytest.traverse()

