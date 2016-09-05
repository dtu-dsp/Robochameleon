% This is an advanced example of how to work with signal interface objects.
% 
% The purpose is to demonstrate how power scaling changes after various
% operations

clear
%specify some general properties (these don't matter anywhere here)
Fs = 160e9;
Rs = 10e9;
Fc = const.c/1550e-9;
SNR = 50; 
Psig = 1;

%Generate a random waveform
waveform = randn(100, 2);

%% Make a signal_interface object such that get(obj) = getRaw(obj)
%step 1: calculate waveform power
Ptot = pwr.meanpwr(waveform);
P_percol(1) = pwr(SNR, {Ptot(1), 'W'});     %note I have to tell pwr constructor that power is set in W, not dBm
P_percol(2) = pwr(SNR, {Ptot(2), 'W'});
%pass to constructor
sig_scaled = signal_interface(waveform, struct('PCol', P_percol, 'Fs', Fs, 'Rs', Rs, 'Fc', Fc));
%plot, for comparison
time = 1:sig_scaled.L;
figure(1)
plot(time, waveform, time, getScaled(sig_scaled), ':');

%There are incorrect ways to do this, for example
sig_scaled_bad = signal_interface(waveform, struct('P', pwr(SNR, {mean(Ptot), 'W'}), 'Fs', Fs, 'Rs', Rs, 'Fc', Fc));
hold on
plot(time, getScaled(sig_scaled_bad), ':')
hold off
%This messes up a little (for this example), because the signal_interface
%constructor assumes the power is evenly split among the signals, and in
%this example it's usually not.

%% Demonstrate the use of fun1

%construct a signal with specified power (1dBm)
sig_orig = signal_interface(waveform, struct('P', pwr(SNR, Psig), 'Fs', Fs, 'Rs', Rs, 'Fc', Fc));
sig_inverted = fun1(sig_orig, @(x)-x);       %can also use multiplication

time = 1:sig_orig.L;
figure(2)
plot(time, get(sig_orig), time, get(sig_inverted));

%show an example of this working "oddly"
figure(3)
sig_DCoffset_bad = fun1(sig_orig, @(x) x+5);
plot(time, get(sig_orig), time, get(sig_DCoffset_bad));
%note DC offset not actually 5!  This is because we add 5 to the original
%waveform, whatever units it happens to be in, then rescale everything.
%Needless to say, this is a bad idea. It does not work and should not work
%because the waveform is stored in arbitrary units.

%show an example of fun1 being useful
figure(4)
[b, a] = butter(2, 0.1);
sig_filtered = fun1(sig_orig, @(x) filter(b,a,x));
plot(time, get(sig_orig), time, get(sig_filtered));