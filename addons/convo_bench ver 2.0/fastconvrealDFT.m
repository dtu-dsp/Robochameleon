function z = fastconvrealDFT(x,y)
% Compute the linear convolution of 2 real sequences via FFT's.
% This function takes care of the sizes of the 2 input sequences and zero-pads them 
% to a common length L = 2^n. 
%
% Input arguments:
%   x is a row vector that contains the real-valued sequence x[n].
%   y is a row vector that contains the real-valued sequence y[n].
%
% Output Arguments:
%   z : vector containing the real convolution values of x[n] and y[n].

% Make sure x and y are row vectors.
    x = x(:).';
    y = y(:).';

    N = length(x);
    M = length(y);

    L = M+N-1; 
    
    % Make sure L is even for use with fftreal.m function.
    if mod(L,2)==0   % if L is already even ...
       x1 = [x zeros(1,L-N)];  % Zero-pad as required to make the length
       y1 = [y zeros(1,L-M)];  % of both sequences equal to L=M+N-1 (even).
    else              % if L is odd ...
       x1 = [x zeros(1,L-N+1)];  % Zero-pad as required to make the length
       y1 = [y zeros(1,L-M+1)];  % of both sequences equal to L=M+N (even).
   %  L = L + 1;  % Correct but useless...
    end

% Calculate the real version of the fft for speed benefits:
    X = fftreal(x1);
    Y = fftreal(y1);

    Z = X.*Y;

% Calculate the ifft of Z taking advantage its special structure
% which corresponds to a DFT of a real signal:
    z1 = ifftreal(Z);
 
 % Return the values and time indices of the linear convolution:
 % (this line excludes only the last sample of z[n] when M+N-1 is odd):
    z = z1(1,1:N+M-1);
    
end


function Xs = fftreal(x)
% This function calculates the FFT of an N-point real signal x[n] by use
% of function fft241.m. First, we break down the given sequence into
% two N/2 point sequences, then use fft241.m and finally the radix-2
% Decimation In Time relations to compute the FFT of the whole sequence. 
% Caution: Works well only for N even.
    N = length(x);
    k = 0:N/2-1;
    W = exp(-1i*2*pi*k/N);

 % even_time_ind = 1:2:N-1; % Form the even sequence x[0], x[2], x[4], ..., x[N-2].
 % odd_time_ind   = 2:2:N;    % Form the odd sequence   x[1], x[3], x[5], ..., x[N-1].

% Form two REAL sequences x1 and y1:
%    x1 = x(even_time_ind);
%    y1 = x(odd_time_ind);
    x1 = x(1:2:N-1);
    y1 = x(2:2:N);

% Use fft241.m to compute the two N/2 DFT's:
    [X Y] = fft241(x1,y1);

% Use radix-2, Decimation-In-Time (DIT) relations to compute the DFT of x[n].
    Xs = zeros(1,N);
    Xs(1:N/2)      = X + W.*Y;
    Xs(N/2+1:N) = X - W.*Y;
end


function [X Y] = fft241(x,y)
% This function calculates the DFT's of two real N-point sequences, by means of
% a single N-point complex DFT evaluation.
% Make sure x and y are row vectors.
    x = x(:).';
    y = y(:).';

    z = x + 1i*y;  % Form the complex sequence z[n].
    Z = fft(z);
 
    X =        1/2*(Z + conj(circshift(fliplr(Z),[0 1])));  % even sequence
    Y = 1/(2*1i)*(Z -  conj(circshift(fliplr(Z),[0 1])));  % odd sequence
end


function x = ifftreal(X)
% This function computes the ifft of an N-point complex DFT sequence which corresponds
% to a real signal x[n]. i.e. Re{X[k]} should be even and Im{X[k]} should be odd in order for
% this to work properly. This routine makes use of ifft241.m custom function which employs 
% a single ifft to calculate the inverse DFT's of 2 real signals. However, in this case,
% there is no real computational speed gain.

[x  y] = ifft241(real(X), imag(X));

% ifft241.m yields maximum performance when both inputs X and Y are complex
% DFT's corresponding to 2 real signals x[n] and y[n]. Here, we only invert
% a single DFT sequence.
end


function [x y] = ifft241(X,Y)
% This function calculates the IDFT's of 2 given real DFT sequences of common length N,
% using a single inverse fft of a combined complex sequence of the same duration.
% X and Y must correspond to the real and imaginary parts of the DFT of 1 real signal.
% i.e. X[k] should be even and Y[k] should be odd.
%
% Also, the symmetry of Re{X[k]} and Re{Y[k]} as well as of Im{X[k]} and Im{Y[k]} should be identical.
% i.e. Re{X[k]} and Re{Y[k]} should both have even or odd symmetry around the middle sample.
% also, Im{X[k]} and Im{Y[k]} should  both have even or odd symmetry around the middle sample.

Z = X + 1i*Y;
z = ifft(Z);
x = real(z);
y = imag(z);
end