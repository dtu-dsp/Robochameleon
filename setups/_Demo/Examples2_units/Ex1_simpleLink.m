% This is an example of how to work with units in "script mode"
% 
% A binary data sequence is generated, noise is added, and then errors are
% counted.
%

%% CLEAR
clearall
close all
clc;
robochameleon;


%% PARAMETER SETTING

%pick a symbol rate
Rs = 10e9;

%Pattern parameters
param.pg.M = 2;
param.pg.typePattern = 'PRBS';
param.pg.PRBSOrder = 15;
param.pg.lengthSequence = 2^16;
param.pg.seed = 29681;      %Makes script mode easier

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

%% MAIN SIMULATION

%Generate data to transmit
patterngenerator = PatternGenerator_v1(param.pg);
binarySequence = patterngenerator.traverse();

%Set symbol rate.  The output of PatternGenerator_v1 is just a binary sequence.  
% Normally one would use a unit for this with some kind of modulator model,
% but we don't have one for such a simple link
dataSequence = set(binarySequence, 'Rs', Rs, 'Fs', Rs);

%load noise
noiseloader = SNR_v1(param.SNR);
noisyData = noiseloader.traverse(dataSequence);

%count errors
BERT = BERT_v4(param.bert);
BERT.traverse(noisyData);




