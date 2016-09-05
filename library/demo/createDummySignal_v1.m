function [ sigOut ] = createDummySignal_v1()
param.ptg.avgPower    = 0;
param.ptg.nPulses     = 1e3;
param.ptg.Rs          = 1e9;
param.ptg.Fs          = 100e9;
param.ptg.wavelength  = 1550.3;
param.ptg.shape       = 'gaussian'; % gaussian rect nyquist
param.ptg.T0          = 1/param.ptg.Rs*0.2;

ptg = PulseTrainGenerator_v1(param.ptg);
sigOut = ptg.traverse();

% Generate second polarization
param.pbs.bases = ones(2);
param.pbs.nOutputs = 2;
param.pbs.align_in = [1 1]/sqrt(2);
pbs = PBS_1xN_v1(param.pbs);
sigOut = pbs.traverse(sigOut);
end

