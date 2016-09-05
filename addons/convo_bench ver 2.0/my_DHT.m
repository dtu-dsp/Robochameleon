function X = my_DHT(x)
% This function calculates the Discrete Hartley Transform of a real
% sequence. In this function the time and frequency indices run from 0 to
% N-1. Therefore, when we use this function we consider strictly causal
% signals and only nonnegative frequencies.

% Take advantage of the fact that the input sequence x[n] is real:
  X1 = fftreal(x);    % only for sequence x of even length.
  X = real(X1) - imag(X1);
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
 %   y1 = x(odd_time_ind);
    x1 = x(1:2:N-1);
    y1 = x( 2:2:N);

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