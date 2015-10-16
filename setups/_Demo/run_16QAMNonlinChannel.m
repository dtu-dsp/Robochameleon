% This runs setup_16QAMLinChannel, a 16QAM setup with transmission over a 
% nonlinear channel, with realistic impairments and a full receiver chain in
% the DSP
%
% The parameters in this file are "typical" parameters for this kind of
% link.  For definitions, consult the relevant units or modules
%
% The final cell in this file will sweep OSNR and find the BER

robochameleon
clear
close all
close_biographs


%% Parameter definition

%MAIN CONTROLS
M = 16;     %modulation order
Rs = 28e9;  %symbol rate
L = 2^16;   %sequence length

% PULSE PATTERN GENERATOR
param.ppg = struct('order', 15, 'total_length', L, 'Rs', Rs, 'nOutputs', log2(M)/2, 'levels', [-1 1]);
% PULSE SHAPING
param.ps = struct('US_factor', 16, 'type', 'Gaussian', 'bandwidth', 0.75, 'rolloff', 0.5, 'Nsym', 4);
% TX LASER
param.laser = struct('Power', pwr(150, {-3, 'dBm'}), 'linewidth', 100e3, ...
    'Fs', param.ppg.Rs*param.ps.US_factor, 'Rs', Rs, 'Fc', const.c/1550e-9, ...
    'Lnoise', param.ps.US_factor*L, 'L', 2^12);
% IQ MODULATOR
param.iq.mode = 'single';
% CHANNEL
param.nlinch.nSpans      = 2;
param.nlinch.dispersionCompensationEnabled  = 0;
param.nlinch.polarizationMixingEnabled = 0;
param.nlinch.L          = [80 80];
param.nlinch.stepSize   = 5;
param.nlinch.iterMax    = 15;
param.nlinch.alpha      = 0.2;
param.nlinch.D          = 17;
param.nlinch.S          = [0.2 0.2];
param.nlinch.gamma      = 1.7;
param.nlinch.EDFANF    = [5 5];
param.nlinch.EDFAGain  = [16 16];

% COHERENT FRONT END
foffset = 40e6;
LOparam = struct('Power', pwr(150, {5, 'dBm'}), 'linewidth', 100e3, 'Fc', const.c/1550e-9+foffset);
PBSparam = struct('bases', eye(2), 'nOutputs', 2);
BPDparam = struct('R', 1, 'CMRR', 50, 'f3dB', 28e9, 'Rtherm', 50);
param.coh.LO = LOparam;
param.coh.LOPBS = catstruct(PBSparam, struct('align_in', [1 1]/sqrt(2)));
param.coh.sigPBS = PBSparam;
param.coh.hyb.phase_angle = pi/2;
param.coh.bpd = BPDparam;
% ADC
param.ADC=struct('nOutputs', 4, 'nInputs', 4, 'SamplingRate', 80e9);

% TIMING RECOVERY
param.retiming = struct('newFs', 16*Rs, 'method', 'gardner');
param.decimator.Nss=2;
% CD COMPENSATION
param.cdcomp = struct('D',-17,'S',0.0,'L',sum(param.nlinch.L), 'lambda',1550e-9);
% EQUALIZATION AND CARRIER RECOVERY
param.dsp.eq = struct('type', 'mma', 'h_ortho', true, 'iter', 3, ...
    'taps', 15, 'cma_preconv', 10e3, 'equalizer_conv', 20e3, 'mu', 6e-4, ...
    'constellation', [constref('QAM',M)]);
PI_BW = 10e6;
param.dsp.crm = struct('speedup', 0, 'Kv', 0.2, 'omega_DCO', 0e6, 'conv', 0, ...
    'Ts', 1/param.ppg.Rs, 'tau1', 1/(2*pi*PI_BW), 'tau2', 1/(2*pi*PI_BW), 'init_phase', 0, ...
    'const_type', 'QAM', 'M', M);

param.bert = struct('M', M, 'dimensions', 1, 'coding', 'bin', 'prbs', gen_prbs(15), 'PostProcessMethod', 'threshold 0.1');
                  
%% System construction and run
coherentLink = setup_16QAMNonlinChannel(param);
traverse(coherentLink)

