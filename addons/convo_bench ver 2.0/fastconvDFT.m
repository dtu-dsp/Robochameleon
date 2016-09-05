function z = fastconvDFT(x,y)
% Compute a linear convolution via DFT's. This function accepts as
% input arguments real and/or complex signals in vector format.
% This function takes care of the sizes of the 2 input sequences  and 
% zero-pads them to a common length L = N+M-1.
%
% Inputs:
%            x : is a real or complex input signal in vector format.
%            y : is a real or complex input signal in vector format.
%
% Outputs:
%            z : is the convolution of input signals x and y as a vector.

% Make sure x and y are row vectors.
x = x(:).';
y = y(:).';

N = length(x);
M = length(y);
L  = N+M-1;
 
x1 = [x zeros(1,L-N)];  % Zero-pad as required to make the length
y1 = [y zeros(1,L-M)];  % of both sequences equal to L.

X = fft(x1);
Y = fft(y1);

Z = X.*Y;

z = ifft(Z);