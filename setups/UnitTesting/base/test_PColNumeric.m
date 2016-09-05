%test power
clearall
close all

vpp = 4;
testsig = randn(100, 2);
testsig(testsig>0) = vpp/2;
testsig(testsig<0) = -vpp/2;
testsig(:,2) = testsig(:,2)*0.5;

[PCol] = getPColFromNumeric_v1(testsig, [10, 30].');

sigparams.Fs = 1;
sigparams.Rs = 1;
sigparams.Fc = 0;
sigparams.PCol = PCol;
test_signal = signal_interface(testsig, sigparams);

preim(test_signal)


%try with a complex signal
vpp2 = 3;
testsig2 = randn(size(testsig));
testsig2(testsig2>0) = vpp2/2;
testsig2(testsig2<0) = -vpp2/2;
testsig2(:,2) = testsig2(:,2)*0.5;
testsig_cplx = testsig + 1i*testsig2;

[PCol_cplx] = getPColFromNumeric_v1(testsig_cplx, [10, 30].');

sigparams.PCol = PCol_cplx;
test_signal_cplx = signal_interface(testsig_cplx, sigparams);

preim(test_signal_cplx)

sigparams_simple = rmfield(sigparams, 'PCol');
sigparams_simple.P = pwr(inf, 38.93);
test_signal_cplx2 = signal_interface(testsig_cplx, sigparams_simple);

preim(test_signal_cplx2)

