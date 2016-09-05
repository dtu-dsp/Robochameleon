close_biographs
clearvars -except testFiles nn
close all

%simple example
nModes = 5;

param.laser = struct('Power', pwr(150, {15, 'dBm'}), 'linewidth', 100e3, ...
    'Fs',28e9*16, 'Fc', const.c/1550e-9+100e6, ...
    'Lnoise', 2^15, 'cacheEnabled', 0);


laser1 = Laser_v1(param.laser);
l1output = laser1.traverse();
l2output = l1output.set(repmat(l1output.get, 1, nModes));



param.nModes = nModes;
CohFrontEnd = CoherentFrontend_v2(param);
[op1] = CohFrontEnd.traverse(l2output);

preim(op1);

%complex constructor example
param.linewidth = 1e6;   %set LO linewidth to 1MHz
param.Fc = const.c/1550e-9+5e9;  %set LO wavelength to 1551 nm

param.phase_angle = deg2rad(89);     %1-degree IQ imbalance

param.CMRR = 50;            %common-mode rejection ratio of balanced pairs
param.f3dB = 32e9;          %3dB bandwidth of balanced pairs

param.gaussianOrder = 2;
param.gaussianBandwidth = 40e9;
param.downsamplingRate = 1;     %downsampling not currently functional
param.targetENoB = 6;
param.bitResolution = 8;

CohFrontEndComplex = CoherentFrontend_v2(param);
op2 = CohFrontEndComplex.traverse(l2output);

preim(op2);
