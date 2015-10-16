% Run "DemoSetup" example
%
% setup_DemoSetup.m is a link with the simplest possible configuration.
% This script constructs the setup, then sweeps SNR and gets BER

%Initialize Matlab (add relevant folders to path)
robochameleon;

close all
close_biographs
clear

%link parameters
param.ppg.order=15;
param.ppg.Rs=25e9;
param.ppg.total_length=2^16;
param.ppg.nOutputs=2;
param.SNR.SNR=10;
param.SNR.M=2;
param.bert.M=param.SNR.M;
param.bert.margin = 0;
param.bert.ConstType = 'ASK';

%constructor
mydemo = setup_DemoSetup(param);

%find relevant units in setup
%alternative syntax would be:
%setSNR = mydemo.internalUnits{3};
setSNR = findUnit(mydemo, 'SNR_v1');
BERT = findUnit(mydemo, 'BERT_v1');

%sweep
snr = 5:15;
ber = nan(size(snr));
for i = 1:length(snr);
    setSNR.SNR=snr(i);  %change SNR
    mydemo.traverse();  %run simulation
    ber(i) = BERT.results.ber;  %get result
end

%plot BER vs. SNR
figure, semilogy(snr,log10(ber))
xlabel('SNR/bit (dB)')
ylabel('log_{10}(BER)')

