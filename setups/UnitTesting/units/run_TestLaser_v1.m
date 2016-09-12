clearvars -except testFiles nn
close all

%plot PSD of phase noise for Lorentzian lineshape laser

%generate field
param.laser1 = struct('Power', pwr(150, {5, 'dBm'}), 'linewidth', 100e3, ...
    'Fs',28e9*16, 'Rs', nan, 'Fc', const.c/1550e-9, ...
    'Lnoise', 2^15, 'cacheEnabled', 0);

laser1 = Laser_v1(param.laser1);
field_laser1 = laser1.traverse();

%compute PSD
[Sf_num, f] = periodogram(diff(unwrap(angle(get(field_laser1)))), gausswin(field_laser1.L-1), 2^15, field_laser1.Fs);
cfact=4*(sin(pi*f/field_laser1.Fs)./f).^2;
figure
loglog(f, Sf_num./cfact*pi, f, param.laser1.linewidth*ones(size(f)))

%plot PSD of phase noise for semiconductor lineshape laser (no 1/f noise)
param.laser2 = struct('Power', pwr(150, {5, 'dBm'}), ...
     'alpha', 3, 'fr', 1e9, 'K', .2e-9, 'LFLW1GHZ', 1e5, 'HFLW', 1e5, ...
    'Fs',28e9*16, 'Rs', nan, 'Fc', const.c/1550e-9, ...
    'Lnoise', 2^15, 'L', 2^12, 'cacheEnabled',0);

laser2 = Laser_v1(param.laser2);
field_laser2 = laser2.traverse();

%compute PSD
[Sf_num, f] = periodogram(diff(unwrap(angle(get(field_laser2)))), gausswin(field_laser2.L-1), 2^15, field_laser2.Fs);
cfact=4*(sin(pi*f/field_laser1.Fs)./f).^2;
%analytical PSD for comparison
Sf = (1/pi)*param.laser2.HFLW*(1+param.laser2.alpha^2*param.laser2.fr^4./((param.laser2.fr^2-f.^2).^2+(param.laser2.K/2/pi)^2*param.laser2.fr^4*f.^2));
figure
loglog(f, Sf_num./cfact*pi, f, Sf)
