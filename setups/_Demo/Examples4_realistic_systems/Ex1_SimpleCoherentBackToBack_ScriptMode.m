% Run a simple coherent transmission example as a script
%
% This is a simple "back-to-back" setup with no channel or noise.  However,
% there is some quantization noise at the transmitter and receiver, as well
% as normal shot noise and electrical noise in the receiver.

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

%% Receive the signal
param.rx.linewidth          = 100e3;                %linewidth of coherent receiver LO
param.rx.Fc                 = TxField.Fc+100e6;     %Frequency offset
param.rx.nModes             = 2;                    %number of optical modes in signal to receive
param.rx.gaussianBandwidth  = 32e9;                 %analog-digital converter analog bandwidth
param.rx.gaussianOrder      = 6;                    %analog-digital converter filter order
param.rx.outputSamplingRate = 80e9;                 %Output sample rate

Receiver = CoherentFrontend_v2(param.rx);

RxField = Receiver.traverse(TxField);

%% Digital signal processing
%NB: a real system should have a low-pass filter, IQ imbalance correction,
%and proper clock recovery

%Resample to 2 samples per symbol
param.DSP.newFs             = 2*param.tx.symbolRate;
Resampler = Resample_v1(param.DSP);
ProcessedField = Resampler.traverse(RxField);

%Equalization using radially directed eq. w/ default parameters
param.DSP.constellation = constref(param.tx.modulationFormat, param.tx.M);
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

