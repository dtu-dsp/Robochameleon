function w = wspace(t,nt);

% This function constructs a linearly-spaced vector of angular
% frequencies that correspond to the points in an FFT spectrum.
% The second half of the vector is aliased to negative
% frequencies.
% 
% USAGE
%
% w = wspace(tv);
% w = wspace(t,nt);
%
% INPUT
%
% tv - vector of linearly-spaced time values
% t - scalar representing the periodicity of the time sequence
% nt - Number of points in time sequence 
%      (should only be provided if first argument is scalar)
%
% OUTPUT
%
% w - vector of angular frequencies
% 
% EXAMPLE
%
%   t = linspace(-10,10,2048)';   % set up time vector
%   x = exp(-t.^2);               % construct time sequence
%   w = wspace(t);                % construct w vector
%   Xhat = fft(x);                % calculate spectrum
%   plot(w,abs(Xhat))             % plot spectrum
%
% AUTHOR:  Thomas E. Murphy (tem@umd.edu)

if (nargin<2)
  nt = length(t);
  dt = t(2) - t(1);
  t = t(nt) - t(1) + dt;
end

if (nargin == 2)
  dt = t/nt;
end

w = 2*pi*(0:nt-1)'/t;
kv = find(w >= pi/dt);
w(kv) = w(kv) - 2*pi/dt;
