clearvars -except testFiles nn
close all
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Check SimpleAWG_v1/ExtendedAWG_v1 to have this functionality in one module
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%% Parameters
% Waveform Generator parameters
param.M                 = 4;        % Modulation order
param.modulationFormat  = 'QAM';    % Modulation format
param.N                 = 2;        % Number of modes (not necessary)
param.samplesPerSymbol  = 16;       % Samples per symbol
param.pulseShape        = 'rrc';    % Pulse shape
param.rollOff           = 0.2;      % Rolloff factor

% DAC parameters
param.DACGaussianOrder     = 1;        % (not necessary)
param.DACGaussianBandwidth = 18e9;     % (not necessary)
param.DACBesselOrder         = 0;      % (not necessary)
param.DACBesselBandwidth     = 110e9;  % (not necessary)

param.outputVoltage     = 2.0;      % (not necessary)
param.amplitudeImbalance= 1;        % (not necessary)
param.skew              = [0.0 0.5];% (not necessary)
param.jitterVariance    = 1e-8;     % (not necessary)
param.upsamplingRate    = 2;        % (not necessary)
param.clockError        = 1e-6;     % (not necessary)

%% Create object
wg  = WaveformGenerator_v1(param);
dac = DAC_v1(param);

%% Traverse object
out  = wg.traverse();
out2 = dac.traverse(out);


