% Run "SimpleLink" example
%
% SimpleLink.m is a link with the simplest possible configuration.
% This script constructs the setup, then runs it
%
% The signal at the output of each unit can be inspected by double clicking
% the name of the unit in the biograph (system diagram)

%% Initialize Matlab (add relevant folders to path)
robochameleon;
addpath('setups')
setpref('robochameleon', 'debugMode', 1)        %make sure unit outputs will be available to view

clearall
close all
close_biographs
clc;

%% PARAMETER SETTING

%Pattern parameters
param.pg.M = 2;
param.pg.typePattern = 'PRBS';
param.pg.PRBSOrder = 15;
param.pg.lengthSequence = 2^16;
param.pg.seed = 29681;      %Makes BERT construction easier

%Pulse shaper parameters
param.ps.samplesPerSymbol = 1;
param.ps.pulseShape = 'nrz';
param.ps.symbolRate = 10e9;

%Noise loading
param.SNR.SNR = 10;
param.SNR.M = param.pg.M;

%Error counting
% get transmitted data using static method from PatternGenerator_v1
txdata = PatternGenerator_v1.gen_prbs_v1(param.pg.PRBSOrder, ...
    param.pg.seed, ...
    2^param.pg.PRBSOrder-1);
txdata = logical(txdata);
param.bert.TxData = txdata;
param.bert.M = 2;
param.bert.ConstType = 'ASK';

%% RUN SIMULATION

mydemo = SimpleLink(param);
mydemo.traverse();
view(mydemo);


