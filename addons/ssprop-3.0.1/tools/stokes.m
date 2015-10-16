function [S0,S1,S2,S3] = stokes(ux,uy)

S0 = abs(ux).^2 + abs(uy).^2;
S1 = abs(ux).^2 - abs(uy).^2;
S2 = 2*real(conj(ux).*uy);
S3 = 2*imag(conj(ux).*uy);
