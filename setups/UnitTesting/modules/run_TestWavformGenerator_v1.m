clearvars -except testFiles nn
close all

%% Parameters
param.M                 = 4;        % Modulation order
param.modulationFormat  = 'QAM';    % Modulation format
param.N                 = 2;        % Number of modes (not necessary)
param.samplesPerSymbol  = 16;       % Samples per symbol
param.pulseShape        = 'rrc';    % Pulse shape
param.rollOff           = 0.2;    % Rolloff factor

%% Create object
wg = WaveformGenerator_v1(param);
param.M=16;
wg2 = WaveformGenerator_v1(param);
%% Create object
out = wg.traverse();
out2 = wg2.traverse();
%%
preim(out(1:10*param.samplesPerSymbol,1),out2(1:10*param.samplesPerSymbol,1))
%%
pconst(out, out2)