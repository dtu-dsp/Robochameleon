clearvars -except testFiles nn
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TEST 1 - TRANSMITTER %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parameters
param.quantizer.targetENoB      = 7;
param.quantizer.bitResolution   = 8;
param.quantizer.location        = 'Transmitter';

%% Create object
quantizer = Quantizer_v1(param.quantizer);

%% Create Dummy input
param.sig.Fs = 32e9;
param.sig.Fc = 0;
param.sig.Rs = 32e9;
Ein = (-1000000:1000000);
Ein = Ein(randperm(length(Ein))) + 1j*Ein(randperm(length(Ein)));
sigIn = signal_interface(Ein, param.sig);

figure(1), plot((sigIn.get), '.')

%% Traverse
sigOut = quantizer.traverse(sigIn);

figure(2), plot(real(sigOut.get),imag(sigOut.get), '.')

display(quantizer.results)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  TEST 2 - RECEIVER   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except testFiles nn
close all
%% Parameters
param.quantizer.targetENoB      = 7;
param.quantizer.bitResolution   = 8;
param.quantizer.location        = 'Receiver';

%% Create object
quantizer = Quantizer_v1(param.quantizer);

%% Create Dummy input
param.sig.Fs = 32e9;
param.sig.Fc = 0;
param.sig.Rs = 32e9;
Ein = (-1000000:1000000);
Ein = Ein(randperm(length(Ein))) + 1j*Ein(randperm(length(Ein)));
sigIn = signal_interface(Ein, param.sig);

figure(3), plot((sigIn.get), '.')

%% Traverse
sigOut = quantizer.traverse(sigIn);

figure(4), plot(real(sigOut.get),imag(sigOut.get), '.')

display(quantizer.results)


%> @code
%>   % Here we put a FULLY WORKING example using a more extended set of parametersedit
%>   param.quantizer.targetENoB      = 4;
%>   param.quantizer.bitResolution   = 10;
%>   quantizer = Quantizer_v1(param.quantizer);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 193.1e12;
%>   param.sig.Rs = 10e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = 100*randn(1000,2) + 1j*100*randn(1000,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = quantizer.traverse(sigIn);
%> @endcode