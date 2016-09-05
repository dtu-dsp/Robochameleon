clearvars -except testFiles nn
close all

%% Parameters
%General WDM channel
carrier_freqs           = [-4 4 -3 3 -2 2 -1 1 0]*100e9 + 193.4e12; %center at 1550nm, spacing 100 GHz
param.nChannels         = length(carrier_freqs);
param.lambda            = 1e9*const.c./carrier_freqs;
param.modulationFormat  = 'QAM';
param.M                 = 4;
param.pulseShape        = 'rrc';
param.rollOff           = 0.2;

param.N                 = 2; % (not necessary)
param.samplesPerSymbol = 16;

param.linewidth  =   0;%100e3;
param.Power      =   cell(1,length(carrier_freqs));
PLoad = 2.5;    %per-channel launch power for loading channels
PLaunch = -3;   %launch power for center channel
for ii=1:length(carrier_freqs)
    param.Power{ii} = pwr(inf, PLoad);
    if ii==length(carrier_freqs)
        param.Power{ii} = pwr(inf, PLaunch);
    end
end

% DACPrecompensator parameters
param.DACPreGaussianOrder     = 1;     % (not necessary)
param.DACPreGaussianBandwidth = 18e9;  % (not necessary)
param.DACPreBesselOrder     = 1;       % (not necessary)
param.DACPreBesselBandwidth = 18e9;    % (not necessary)
param.targetENoB        = 6;        % (not necessary)
param.bitResolution     = 6;        % (not necessary)

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

%% Laser parameters - copies parameters from input signal
% param.linewidth = 100e3;    % (not necessary)
% param.Fs = 80e9;            % (not necessary)
% param.Lnoise = 2^10;        % (not necessary)


%% Create object
wdmt = ExtendedWDMTransmitter_v1(param);

%% Traverse object
% out = wdmt.traverse();


