function u1 = ssprop(u0,dt,dz,nz,alpha,betap,gamma,maxiter,tol);

% This function solves the nonlinear Schrodinger equation for
% pulse propagation in an optical fiber using the split-step
% Fourier method.
% 
% The following effects are included in the model: group velocity
% dispersion (GVD), higher order dispersion, loss, and self-phase
% modulation (gamma).
% 
% USAGE
%
% u1 = ssprop(u0,dt,dz,nz,alpha,betap,gamma);
% u1 = ssprop(u0,dt,dz,nz,alpha,betap,gamma,maxiter);
% u1 = ssprop(u0,dt,dz,nz,alpha,betap,gamma,maxiter,tol);
%
% INPUT
%
% u0 - starting field amplitude (vector)
% dt - time step
% dz - propagation stepsize
% nz - number of steps to take, ie, ztotal = dz*nz
% alpha - power loss coefficient, ie, P=P0*exp(-alpha*z)
% betap - dispersion polynomial coefs, [beta_0 ... beta_m]
% gamma - nonlinearity coefficient
% maxiter - max number of iterations (default = 4)
% tol - convergence tolerance (default = 1e-5)
%
% OUTPUT
%
% u1 - field at the output
% 
% NOTES  The dimensions of the input and output quantities can
% be anything, as long as they are self consistent.  E.g., if
% |u|^2 has dimensions of Watts and dz has dimensions of
% meters, then gamma should be specified in W^-1*m^-1.
% Similarly, if dt is given in picoseconds, and dz is given in
% meters, then beta(n) should have dimensions of ps^(n-1)/m.
%
% See also:  sspropc (compiled MEX routine)
%
% AUTHOR:  Thomas E. Murphy (tem@umd.edu)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Copyright 2006, Thomas E. Murphy
%
%   This file is part of SSPROP.
%
%   SSPROP is free software; you can redistribute it and/or
%   modify it under the terms of the GNU General Public License
%   as published by the Free Software Foundation; either version
%   2 of the License, or (at your option) any later version.
%
%   SSPROP is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public
%   License along with SSPROP; if not, write to the Free Software
%   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%   02111-1307 USA

if (nargin<9)
  tol = 1e-5;
end
if (nargin<8)
  maxiter = 4;
end

nt = length(u0);
w = 2*pi*[(0:nt/2-1),(-nt/2:-1)]'/(dt*nt);

halfstep = -alpha/2;
for ii = 0:length(betap)-1;
  halfstep = halfstep - j*betap(ii+1)*(w).^ii/factorial(ii);
end
halfstep = exp(halfstep*dz/2);

u1 = u0;
ufft = fft(u0);
for iz = 1:nz,
  uhalf = ifft(halfstep.*ufft);
  for ii = 1:maxiter,
    uv = uhalf .* exp(-j*gamma*(abs(u1).^2 + abs(u0).^2)*dz/2);
	uv = fft(uv);
    ufft = halfstep.*uv;
    uv = ifft(ufft);
    if (norm(uv-u1,2)/norm(u1,2) < tol)
      u1 = uv;
      break;
    else
      u1 = uv;
    end
  end
  if (ii == maxiter)
    warning(sprintf('Failed to converge to %f in %d iterations',...
        tol,maxiter));
  end
  u0 = u1;
end
