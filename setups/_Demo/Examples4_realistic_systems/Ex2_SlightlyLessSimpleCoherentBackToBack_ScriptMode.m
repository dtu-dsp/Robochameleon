% Run a simple coherent transmission example as a script
%
% This is a simple "back-to-back" setup with no channel or noise.  However,
% there is some quantization noise at the transmitter and receiver, as well
% as normal shot noise and electrical noise in the receiver.  Compared to
% Ex1, this script explicitly sets more parameters in the TX, RX, and DSP.
% Performance is better than Ex. 1 because the equalizer parameters are different.

%Initialize
robochameleon;
setpref('robochameleon', 'debugMode', 1)        %make sure unit outputs will be available to view

clearall
close all


%% Generate sequence to transmit

%Parameter choosing - arbitrary waveform generator
param.tx.M                  = 16;        %Modulation order
param.tx.symbolRate         = 28e9;      %Symbol rate
param.tx.N                  = 2;         %Number of modes to transmit
param.tx.modulationFormat   = 'QAM';     %Modulation format
param.tx.pulseShape         = 'rrc';     %Root-raised cosine pulse shaping
param.tx.rollOff            = 0.1;       %roll-off factor for pulse shaping
param.tx.samplesPerSymbol   = 16;        %number of samples per symbol in pulse shaping filter; 
                                         %in the simple AWG, this is also
                                         %the number of samples per symbol
                                         %for the simulation
param.tx.lengthSequence     = 2^16;      %sequence length in symbols
param.tx.gaussianBandwidth  = 30e9;      %Waveform generator analog bandwidth
param.tx.gaussianOrder      = 6;         %Waveform generator bandwidth filter order
param.tx.targetENoB         = 5.5;       %Effective number of bits for DAC
                                      
                                         
%Parameter choosing - coherent optics
param.tx.linewidth          = 100e3;            %transmitter laser linewidth;
param.tx.Power              = pwr(inf, 3);      %transmitter laser launch power
param.tx.Vpi = 4;                               %Vpi for child MZMs
param.tx.Vb = [-4, -4, -4, -4];                 %child MZM bias voltages
param.tx.rescaleVdrive = false;                 %turn off automatic drive voltage scaling
param.tx.IQGainImbalance = 0;                   %I-Q gain imbalance
param.tx.IQphase = [deg2rad(90), deg2rad(90)];  %transmitter modulator IQ angle


%unit construction and run
Transmitter = ExtendedCoherentTransmitter_v1(param.tx);

TxField = Transmitter.traverse();

%% Receive the signal
param.rx.nModes             = 2;                    %number of optical modes in signal to receive
param.rx.linewidth          = 100e3;                %linewidth of coherent receiver LO
param.rx.Fc                 = TxField.Fc+100e6;     %Frequency offset (LO frequency)
param.rx.Power              = pwr(inf, 10);         %LO power
param.rx.phase_angle        = pi/2;                 %hybrid phase angle
param.rx.CMRR               = 50;                   %Common mode rejection ratio for balanced pair
param.rx.f3dB               = 32e9;                 %3dB bandwidth of balanced pair
param.rx.gaussianBandwidth  = 32e9;                 %analog-digital converter analog bandwidth
param.rx.gaussianOrder      = 6;                    %analog-digital converter filter order
param.rx.outputSamplingRate = 80e9;                 %Output sample rate
param.rx.skew               = [0 0.01 0.1 0.11];      %ADC skew

Receiver = CoherentFrontend_v2(param.rx);

RxField = Receiver.traverse(TxField);

%% Digital signal processing
%NB: a real system should have a low-pass filter, IQ imbalance correction,
%and proper clock recovery

%Resample to 2 samples per symbol
param.DSP.newFs             = 2*param.tx.symbolRate;
Resampler = Resample_v1(param.DSP);
ProcessedField = Resampler.traverse(RxField);

%Equalization using radially directed eq. w/ user-specified parameters
param.DSP.constellation = constref(param.tx.modulationFormat, param.tx.M);
param.DSP.iter = 4;                  %Run 4 iterations of CMA/MMA on training seq. (default 1)
param.DSP.taps = 31;                 %number of equalizer taps (default 7)
param.DSP.mu = 1e-3;                 %update coefficient (default 6e-4)
param.DSP.h_ortho = true;            %Force-orthogonalize taps to avoid CMA singularity
param.DSP.cma_preconv = 10000;       %Run CMA this many samples
param.DSP.equalizer_conv = 20000;    %Train equalizer this many samples
Equalizer = AdaptiveEqualizer_MMA_RDE_v1(param.DSP);
ProcessedField = Equalizer.traverse(ProcessedField);

%Carrier recovery using decision-directed phase-locked loop
param.DSP.constellationType = param.tx.modulationFormat;
param.DSP.M = param.tx.M;
CarrierRecovery = DDPLL_v1(param.DSP);
ProcessedField = CarrierRecovery.traverse(ProcessedField);

%% Count errors

%get reference sequence
PatternGen = findUnit(Transmitter, 'PatternGenerator_v1');
TxBits = PatternGenerator_v1.gen_prbs_v1 (PatternGen.PRBSOrder, PatternGen.seed(1), 2^PatternGen.PRBSOrder-1);

%construct BERT and count errors
param.BERT.M = param.tx.M;
param.BERT.ConstType = param.tx.modulationFormat;
param.BERT.TxData = logical(TxBits);
param.BERT.DecisionType = 'hard';
BERT = BERT_v1(param.BERT);
BERT.traverse(ProcessedField)

