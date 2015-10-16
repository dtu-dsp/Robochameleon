function u = sechpulse(t,t0,FWHM,P0,C)
  
% This function computes a hyperbolic secant pulse with the
% specified parameters:
%
%   sqrt(P0)*sech((t-t0)/T)*exp{-i(C/2)*[(t-t0)/T]^2}
%     where T = FWHM / (2*acosh(sqrt(2)))
% 
% USAGE:
% 
% u = sechpulse (t);
% u = sechpulse (t,t0);
% u = sechpulse (t,t0,FWHM);
% u = sechpulse (t,t0,FWHM,P0);
% u = sechpulse (t,t0,FWHM,P0,C);
% 
% INPUT:
% 
% t     vector of times at which to compute u
% t0    center of pulse (default = 0)
% FWHM  full-width at half-intensity of pulse (default = 1)
% P0    peak intensity (|u|^2 at t=t0) of pulse (default = 1)
% C     chirp parameter (default = 0)
% 
% OUTPUT:
% 
% u     vector of the same size as t, representing pulse
%       amplitude

  
if (nargin<5)
  C = 0;
end
if (nargin<4)
  P0 = 1;
end
if (nargin<3)
  FWHM = 1;
end
if (nargin<2)
  t0 = 0;
end

T0 = FWHM/(2*acosh(sqrt(2)));
u = sqrt(P0)*sech((t-t0)/T0).*exp(-i*C*(t-t0).^2/(2*T0^2));
