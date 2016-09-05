clearvars -except testFiles nn
close all

%% Parameters
param.ups.resamplingRate = 1/8;     % resampling rate
param.ups.skew = [0 0.5];         % skew per electrical line
param.ups.jitterVariance = 1e-8;  % Variance of Jitter Added
param.ups.clockError = 0*5e-6;      % Clock Error Introduced
%% Create object
upsamp = ResampleSkewJitter_v1(param.ups);

%% Create Dummy input
param.sig.Fs = 32e9;
param.sig.Fc = 0;
param.sig.Rs = 32e9;
Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,1);
sigIn = signal_interface(Ein, param.sig);

eyediagram(sigIn.get, 4)


%% Traverse
sigOut = upsamp.traverse(sigIn);

eyediagram(sigOut.get, 32)