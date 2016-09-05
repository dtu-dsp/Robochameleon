clearvars -except testFiles nn
close all


param.laser.Power = pwr(150, {14, 'dBm'});
param.laser.linewidth = 100;
param.laser.Fs = 160e9;
param.laser.Rs = 1e9;
param.laser.Fc = const.c/1550e-9;
param.laser.Lnoise = 1e4;    

param.drive.Fs = 160e9;
param.drive.Rs = 1e9;
param.drive.Fc = 0;
param.drive.P = pwr(inf, 0);


%% Do the simulation
laser = Laser_v1(param.laser);
laserSig = laser.traverse();

t = genTimeAxisSig(laserSig);
driveField = exp(2*1i*pi*param.drive.Rs*t);
driveSig = signal_interface(driveField, param.drive);
driveSig = driveSig.set('P', pwr(30, driveSig.P.Ptot));
IQ = IQModulator_v1();

laserModulated = IQ.traverse(driveSig, laserSig);


plot(laserModulated.get, '.')
axis equal


%% Simulation v 2
dataI = rand(laserSig.L, 1);
dataQ = rand(laserSig.L, 1);
driveField = double(dataI>0.5) + 1i*double(dataQ>0.5);
driveField = driveField-mean(driveField);
driveSig = signal_interface(driveField, param.drive);
laserModulated2 = IQ.traverse(driveSig, laserSig);
plot(laserModulated2.get, '.')


