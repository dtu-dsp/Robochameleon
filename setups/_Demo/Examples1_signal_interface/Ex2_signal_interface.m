% This is an example of how to work with signal interface objects.
% 
% There are no units, modules, etc., just signal operation
%   (1) constructor
%   (2) addition
%   (3) get

robochameleon
close all

%Generate two sinusoids with zero carrier freq. and test addition
%note power scaling is set in constructor, NOT raw waveform
s1= sin((1:10)/pi).';
s2 = sin((1:10)/pi).';
si1 = signal_interface(s1,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(50,0)))
si2 = signal_interface(s2,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(50,3)))
si12 = si1+si2
preim(si1);
hold on
preim(si2);
hold on
preim(si12);
subplot(121);
legend('Signal 1', 'Signal 2', 'Sum', 'Location', 'best')
hold off

%Show effect of frequency offset
s3 = sin((1:10)/pi).';
s4 = sin((1:10)/pi).';
si3 = signal_interface(s3,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(50,0)))
si4 = signal_interface(s4,struct('Fs',10e9,'Fc',1e9,'Rs',1e9,'P',pwr(50,3))) % pure noise 0 dBm
si34 = si3+si4

preim(si3);
hold on
preim(si4);
hold on
preim(si34);
subplot(121);
legend('Signal 3', 'Signal 4', 'Sum', 'Location', 'best')
hold off

%Example of how to construct a new signal with a new field but the same parameters 
%as the old one:
si3 = si1.set(randn(1, 10))

%Example of how to construct a new signal by changing an old signal's
%parameter but keeping everything else
si4a = si2.set('Fc', 1e9);
preim(si4);
hold on
preim(si4a);

%you can change multiple parameters at a time
si4b = si2.set('Fc', 1e9, 'P', pwr(-inf, 3));

%the difference between getRaw and get:
field1 = get(si4);
field2 = getRaw(si4);
figure();
plot(field1);
hold on
plot(field2);
legend('Scaled waveform', 'Raw waveform')
hold off




