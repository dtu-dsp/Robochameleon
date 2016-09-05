% Run a simple coherent transmission example as a script
%
% This is a simple setup with a linear channel and noise.

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
                                      
                                         
%Parameter choosing - coherent optics
param.tx.linewidth          = 100e3;    %transmitter laser linewidth;


%unit construction and run
Transmitter = SimpleCoherentTransmitter_v1(param.tx);

TxField = Transmitter.traverse();

%% Channel

%linear channel
param.ch.loss       = 0.2;        %Set loss to 0dB/km so we know how much gain to use
param.ch.L          = 800;       %Length in km.  Dispersion will be drawn from SMF lookup table
Fiber = LinChBulk_v1(param.ch);
ChField = Fiber.traverse(TxField);

%Noiseless EDFA at output
param.ch.Gain       = param.ch.loss*param.ch.L;     %Gain for single EDFA at output
EDFA = Gain_v1(param.ch);
ChField = EDFA.traverse(ChField);

%Noise loading
param.ch.OSNR = 18;
NoiseLoader = OSNR_v1(param.ch);
ChField = NoiseLoader.traverse(ChField);

%% Receive the signal
param.rx.linewidth          = 100e3;                %linewidth of coherent receiver LO
param.rx.Fc                 = TxField.Fc+100e6;     %Frequency offset
param.rx.nModes             = 2;                    %number of optical modes in signal to receive
param.rx.gaussianBandwidth  = 32e9;                 %analog-digital converter analog bandwidth
param.rx.gaussianOrder      = 6;                    %analog-digital converter filter order
param.rx.outputSamplingRate = 80e9;                 %Output sample rate

Receiver = CoherentFrontend_v2(param.rx);

RxField = Receiver.traverse(ChField);

%% Digital signal processing

%Rectangular low-pass filter
param.DSP.bandwidth = param.tx.symbolRate*1.1;        %Filter BW includes + and - frequencies
LPF = BaseBandFilter_v1(param.DSP);
ProcessedField = LPF.traverse(RxField);

%Dispersion compensation
param.DSP.L = param.ch.L;
param.DSP.D = -Fiber.D;                              %Fiber dispersion parameter: default is not quite correct
CDComp = CDCompensation_v1(param.DSP);
ProcessedField = CDComp.traverse(ProcessedField);

%Resample to 2 samples per symbol
param.DSP.newFs             = 2*param.tx.symbolRate;
Resampler = Resample_v1(param.DSP);
ProcessedField = Resampler.traverse(ProcessedField);

%Equalization using radially directed eq. w/ default parameters
param.DSP.constellation = constref(param.tx.modulationFormat, param.tx.M);
param.DSP.iter = 4;                  %Run 4 iterations of CMA/MMA on training seq. (default 1)
param.DSP.taps = 31;                 %number of equalizer taps (default 7)
param.DSP.mu = 2e-3;                 %update coefficient (default 6e-4)
param.DSP.h_ortho = true;            %Force-orthogonalize taps to avoid CMA singularity
param.DSP.cma_preconv = 20000;       %Run CMA this many samples
param.DSP.equalizer_conv = 50000;    %Train equalizer this many samples
Equalizer = AdaptiveEqualizer_MMA_RDE_v1(param.DSP);
ProcessedField = Equalizer.traverse(ProcessedField);
Equalizer.plotTaps

%Carrier recovery using decision-directed phase-locked loop
param.DSP.constellationType = param.tx.modulationFormat;
param.DSP.M = param.tx.M;
CarrierRecovery = DDPLL_v1(param.DSP);
ProcessedField = CarrierRecovery.traverse(ProcessedField);

%Initial check on signal quality
[EVM, BER_evm, BER_theory, SNR_dB, EbN0_dB, Qfactor_dB, Out] = EVM_Analysis(ProcessedField, param.tx.M, param.tx.modulationFormat);
figure
plot(ProcessedField.get, '.')

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

