close all
clearvars -except testFiles nn

param.laser.Power = pwr(150, {14, 'dBm'});
param.laser.linewidth = 100;
param.laser.Fs = 160e9;
param.laser.Rs = 1e9;
param.laser.Fc = const.c/1550*1e-9;
param.laser.Lnoise = 2^10;    
param.im.Vpi = 6;
param.drive.Fs = 160e9
param.drive.Rs = 1e9;
param.drive.Fc = 0;

%% Linear region MZM
param.im.mode = 'MZM';
param.im.Vbias = -3;
driveAmp = 0.5/2*param.im.Vpi;

%% Nonlinear region MZM p2p
param.im.mode = 'MZM';
param.im.Vbias = -3;
param.im.extinctionRatio=20;
driveAmp = 0.5*param.im.Vpi;

%% Linear region 'linear' p2p
param.im.mode = 'linear';
param.im.Vbias = -3;
param.im.extinctionRatio=inf;
driveAmp = 0.5*param.im.Vpi;

%% Add loss
param.im.loss = 3;

%% Do the simulation
laser = Laser_v1(param.laser);
laserSig = laser.traverse();

t = genTimeAxisSig(laserSig);
driveField = driveAmp*sin(2*pi*param.drive.Rs*t);
driveSig = signal_interface(driveField, param.drive);
driveSig = driveSig.set('P', pwr(30, driveSig.P.Ptot));
im = IntensityModulator_v1(param.im);

laserModulated = im.traverse(driveSig, laserSig);

figure; plot(abs(laserSig.get).^2);
hold on; plot(abs(laserModulated.get).^2);
ll = ylim;
ll(1) = 0;
ylim(ll);
legend('Input signal (power)', 'Output signal (power)')

ER_meas = 10*log10(max(abs(laserModulated.get).^2)/min(abs(laserModulated.get).^2));