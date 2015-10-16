function u = solitonpulse(t,t0,epsilon,N)
  
% This function computes a soliton (sech) amplitude pulse with
% the following parameters:
%
%   N*epsilon*sech(epsilon(t-t0))
% 
% USAGE:
% 
% u = solitonpulse (t);
% u = solitonpulse (t,t0);
% u = solitonpulse (t,t0,epsilon);
% u = solitonpulse (t,t0,epsilon,N);
% 
% INPUT:
% 
% t         vector of times at which to compute u
% t0        center of pulse (default = 0)
% epsilon   scale factor for solition (default = 1)
%           note: make epsilon=2*acosh(sqrt(2)) to get FWHM = 1
% N         soliton order (default = 1)
% 
% OUTPUT:
% 
% u         vector of the same size as t, representing pulse
%           amplitude
  
if (nargin<4)
  N = 1;
end
if (nargin<3)
  epsilon = 1;
end
if (nargin<2)
  t0 = 0;
end

u = N*epsilon*sech(epsilon*(t-t0));

