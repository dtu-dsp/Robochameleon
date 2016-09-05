clearvars -except testFiles nn
close all


%Constructor
Hybrid = OpticalHybrid_v1(1);
PD = BalancedPair_v1(1);


%generate field
param.laser = struct('Power', pwr(150, {15, 'dBm'}), 'linewidth', 100e3, ...
    'Fs',28e9*16, 'Fc', const.c/1550e-9, ...
    'Lnoise', 2^15, 'cacheEnabled', 0);

laser1 = Laser_v1(param.laser);
l1output = laser1.traverse();
l2output = set(l1output, 'Fc', laser1.Fc + 1e9);
dummysignal = l1output.set(zeros(l1output.L, l1output.N));

[s1, s2, s3, s4] = Hybrid.traverse(l1output, l2output);
inphase = PD.traverse(s1, s2);
quadrature = PD.traverse(s3, s4);
attenuated = PD.traverse(s1, dummysignal);
preim(inphase)
hold on
preim(quadrature);
hold on
preim(attenuated)

[spec, freq] = pwelch(inphase(:), [],[],[],inphase.Fs);

%% Try with multimode
nModes = 5;
l1_mm = l1output.set(repmat(get(l1output), 1, nModes));
l2_mm = l2output.set(repmat(get(l2output), 1, nModes));

[s1mm, s2mm, s3mm, s4mm] = Hybrid.traverse(l1_mm, l2_mm);
inphase2 = PD.traverse(s1mm, s2mm);



% Number of components: 1
%        Sampling rate: 448.00 GHz (2.23 ps)
%          Symbol rate: Undefined Bd (Undefined s)
%   Oversampling ratio: Undefined Sa/symbol
%    Carrier frequency: 193.414 THz (1.55000 um)
% 
%          Total power: 11.99 dBm (15.81 mW)
%                  SNR: 150.00 dB (1000000000000000.00)
%         Signal power: 11.99 dBm (15.81 mW)
%          Noise power: -138.01 dBm (0.00 mW)