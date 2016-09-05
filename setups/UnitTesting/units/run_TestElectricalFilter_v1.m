clearvars -except testFiles nn
close all

%% Parameters
param.drivers.rectangularFilter = true;
param.drivers.rectangularBandwidth = 40e9;
param.drivers.gaussianOrder = 2;
param.drivers.gaussianBandwidth = 18e9;
param.drivers.besselOrder = 1;
param.drivers.besselBandwidth = 110e9;
param.drivers.outputVoltage = [2.0]; %Volts
param.drivers.amplitudeImbalance = [0.9 1.1];
param.drivers.levelDC = [0.5 0]; %Volts

%% Create object
drivers = ElectricalFilter_v1(param.drivers);

%% Create Dummy input
param.sig.Fs = 64e9;
param.sig.Fc = 0;
param.sig.Rs = 32e9;
Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,2);
sigIn = signal_interface(Ein, param.sig);

eyediagram(sigIn.get, 4)


%% Traverse
sigOut = drivers.traverse(sigIn);

eyediagram(sigOut.get, 4)