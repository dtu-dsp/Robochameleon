% This is an example of how to work with power objects
% 
% There are no units, modules, etc., just power operations
%   (1) constructor examples
%   (2) addition
%   (3) accessing properties

Psig = pwr(50, 5);        %describe a signal
Pnoise = pwr(-50, {1, 'mw'});   %describe the noise
Pnoise_alt = pwr({1e-5, 'lin'}, 0);   %Pnoise = Pnoise_alt

%use built-in functions to add and calculate SNR, total power
Ptotal = Psig+Pnoise;
fprintf('Power calculated using built-in functions:\n')
disp(Ptotal);

%use built-in functions to access powers, 
%use returned powers to calculate SNR
Ps_total = Psig.Ps('W') + Pnoise.Ps('W');
Pn_total = Psig.Pn('W') + Pnoise.Pn('W');
Ptot_total = Psig.Ptot('W') + Pnoise.Ptot('W');
Ps_dBm = lin2dB(Ps_total)+30;
Pn_dBm = lin2dB(Pn_total)+30;
Pt_dBm = lin2dB(Ptot_total)+30;
fprintf('\n\n')
fprintf('Power calculated in script:\n')
fprintf('Total power %.2f dBm \nSignal power %.2f dBm \nNoise power %.2f dBm \n', Pt_dBm, Ps_dBm, Pn_dBm)

%show an example of gain
P_amplified = 10*Ptotal;
fprintf('\n\n')
fprintf('Power after scalar multiplication by 10:\n')
disp(P_amplified);

%make an array
fprintf('\n\n')
fprintf('An array of power objects:\n')
P_many = [Ptotal Ptotal];
disp(P_many);

%attenuate the array
fprintf('\n\n')
fprintf('attenuate the array of power objects:\n')
P_many_amplified = P_many/10;
disp(P_many_amplified);

