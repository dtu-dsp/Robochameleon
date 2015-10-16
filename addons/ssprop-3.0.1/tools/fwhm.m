function [delta,t0] = fwhm(t,u,tr)

% This function computes the intensity full-width at half maximum
% (FWHM) of the periodic signal u.  
%
% USAGE:
% 
% delta = fwhm(t,u);
% delta = fwhm(t,u,tr);
% [delta,t0] = fwhm(t,u);
% [delta,t0] = fwhm(t,u,tr);
% 
% INPUT:
% 
% t - vector of evenly spaced times
% u - signal to compute the width of (assumed to be strictly
%   positive and periodic).
% tr - if tr is a scalar, the function computes the FWHM of
%   the local maximum nearest to tr.  If tr is a 2-vector, the
%   function finds the maximum which lies in the time range 
%   specified by tr.  If tr is not given, the function finds
%   the finds the width of the tallest peak in the function u.
% 
% OUTPUT:
% 
% delta - the full-width at half maximum of u
% t0 - (optional) the temporal location of the peak
%
% NOTES:
%
% u should be a strictly positive, real quantity, for example
% a power or intensity.  t should be a vector of evenly-spaced
% points in time, representing one full period of a periodic
% sequence.  t and tr must have the same dimensions.

nt = length(u);
dt = diff(t(1:2));
T = dt*nt;
k0 = (1:nt)';
kl = [nt,1:nt-1]';
kr = [2:nt,1]';

if nargin < 3
  [v,ipeak] = max(u);
else
  if length(tr) == 2
	kv = find(tr(1) < t & t < tr(2));
	[v,ipeak] = max(u(kv));
	ipeak = k0(kv(ipeak));
  elseif length(tr) == 1
	itr = interp1(t,k0,tr);
	localmax = find(u(k0) >= u(kl) & u(k0) > u(kr));
	idiff = mod(localmax - itr + nt/2 - 1, nt) - nt/2 + 1;
	[v,i] = min(abs(idiff));
	ipeak = localmax(i);
  end
end

% 3 point quadratic fit to extract peak value

pv = [kl(ipeak),k0(ipeak),kr(ipeak)];
coefs = polyfit((-1:1),[u(pv(1)),u(pv(2)),u(pv(3))],2);
coefs1 = polyder(coefs);
idt = roots(coefs1);
t0 = t(ipeak) + idt*dt;
umax = polyval(coefs,idt);

% find first rising half-max point to left of ipeak

irise = find(u(k0) <= umax/2 & u(kr) > umax/2);
irise = irise + (umax/2 - u(k0(irise)))./(u(kr(irise)) - u(k0(irise)));
irise = min(mod(ipeak-irise,nt));

% find first falling half-max point to right of ipeak

ifall = find(u(k0) >= umax/2 & u(kr) < umax/2);
ifall = ifall + (u(k0(ifall)) - umax/2)./(u(k0(ifall)) - u(kr(ifall)));
ifall = min(mod(ifall-ipeak,nt));

delta = dt*(irise+ifall);
