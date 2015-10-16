% This is an example of how to work with signal interface objects.
% 
% There are no units, modules, etc., just signal operations:
%   (1) constructor
%   (2) addition
%   (3) get

%Generate two random signals and test addition
s1= rand(10,2);
s2 = rand(10,2);
si1 = signal_interface(s1,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(20,3)))
si2 = signal_interface(s2,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(-Inf,0)))
si12 = si1+si2
~any(any(get(si12)-(s1+s2))) % Sanity check; should return 1 if signal_interface works fine

%Generate two more random signals and test addition
s3 = rand(10,2);
s4 = rand(10,2);
si3 = signal_interface(s3,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(5,0))) % pure signal 0 dBm
si4 = signal_interface(s4,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(-Inf,0))) % pure noise 0 dBm
si34 = si3+si4
~any(any(get(si34)-(s3+s4))) % Sanity check; should return 1 if signal_interface works fine
