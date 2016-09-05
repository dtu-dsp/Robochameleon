clearvars -except testFiles nn
close all


%Constructor
BPD = BalancedPair_v1(1);


%generate field
param.laser = struct('Power', pwr(150, {15, 'dBm'}), 'linewidth', 100e3, ...
    'Fs',28e9*16, 'Fc', const.c/1550e-9, ...
    'Lnoise', 2^15, 'cacheEnabled', 0);

laser1 = Laser_v1(param.laser);
l1output = laser1.traverse();

%% CMRR tests - should get decreasing output power with increasing CMRR as
%both inputs are the same
CMRRscan = 10:10:50;
for jj = 1:length(CMRRscan)
    BPD.CMRR = CMRRscan(jj);
    output = BPD.traverse(l1output, l1output);
    Iout(jj) = mean(abs(output(:)));
end
figure(1)
semilogy(CMRRscan, Iout);

 %% Bandwidth test
 fscan = logspace(9, log10(3*BPD.f3dB), 50);        %this is inaccurate at low frequencies due to short sequences 
 BPD.CMRR = inf;
 for jj = 1:length(fscan)
     l2output = set(l1output, 'Fc', laser1.Fc + fscan(jj));
     output = BPD.traverse(l1output+l2output, l1output+l2output*exp(1i*pi));
     spec = pwelch(output(:), [],[],fscan,output.Fs);
     ptone(jj) = sum(spec);
 end
 figure(2)
 semilogx(fscan, 10*log10(ptone))
 
 %% Multimode operation test
 BPD.modeAdditionEnabled = false;
 
 l1mm = set(l1output, [get(l1output) get(l1output)]);
 l2mm =  set(l2output, [get(l2output) get(l2output)]);
 l2mm = l2mm.set('Fc', l1mm.Fc + 1e9);
 BPD.CMRR = [inf, 50];
 BPD.R = [1, 0.75];
 output2 = BPD.traverse(l1mm+l2mm, l1mm+l2mm*exp(1i*pi));
 preim(output2)