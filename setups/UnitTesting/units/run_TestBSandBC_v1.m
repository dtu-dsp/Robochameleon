clearvars -except testFiles nn
close all

param.bs.nOutputs = 3;

param.bc.nInputs = 3;

% Single polarization
bs = BS_1xN_v1(param.bs);
bc = BC_Nx1_v1(param.bc);

sigIn = createDummySignal_v1();
[sig1, sig2, sig3] = bs.traverse(sigIn);
sigOut = bc.traverse(sig1, sig2, sig3);

pabs(sigIn, sig1, sig2, sig3, sigOut);

% Dual polarization
% pol = Polarizer_v1(param.pol)
% siginDualPol = sigIn*[1/sqrt(2) 0; 0 1/sqrt(2)];
