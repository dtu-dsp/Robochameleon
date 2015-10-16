% This function solves the nonlinear Schrodinger equation for
% pulse propagation in an optical fiber using the split-step
% Fourier method.
% 
% The following effects are included in the model: group velocity
% dispersion (GVD), higher order dispersion, loss, self-phase
% modulation, Raman self-frequency shift, and
% self-steepening.
% 
% USAGE
%
% u1 = sspropc(u0,dt,dz,nz,alpha,betap,gamma);
% u1 = sspropc(u0,dt,dz,nz,alpha,betap,gamma,tr);
% u1 = sspropc(u0,dt,dz,nz,alpha,betap,gamma,tr,to);
% u1 = sspropc(u0,dt,dz,nz,alpha,betap,gamma,tr,to,maxiter);
% u1 = sspropc(u0,dt,dz,nz,alpha,betap,gamma,tr,to,maxiter,tol);
%
% INPUT
%
% u0        starting field amplitude (vector)
% dt        time step
% dz        propagation stepsize
% nz        number of steps to take, ie, ztotal = dz*nz
% alpha     power loss coefficient, ie, P=P0*exp(-alpha*z)
% betap     dispersion polynomial coefs, [beta_0 ... beta_m]
% gamma     nonlinearity coefficient
% tr        Raman response time (default = 0)
% to        optical cycle time = lambda0/c (default = 0)
% maxiter   max number of iterations (default = 4)
% tol       convergence tolerance (default = 1e-5)
%
% The loss coefficient alpha may optionally be specified as a
% vector of the same length as u0, in which case it is treated as
% vector that describes alpha(w) in the frequency domain.  (The
% function wspace.m can be used to construct a vector of the
% corresponding frequencies.)
%
% Similarly, the propagation constant beta(w) can be specified
% directly by replacing the polynomial argument betap with a
% vector of the same length as u0.  In this case, the argument
% betap is treated as a vector describing propagation in the
% frequency domain. 
%
% OUTPUT
%
% u1        field at the output
%
% NOTES  The dimensions of the input and output quantities can
% be anything, as long as they are self consistent.  E.g., if
% |u|^2 has dimensions of Watts and dz has dimensions of
% meters, then gamma should be specified in W^-1*m^-1.
% Similarly, if dt is given in picoseconds, and dz is given in
% meters, then beta(n) should have dimensions of ps^(n-1)/m.
%
% OPTIONS
%
% Several internal options of the routine can be controlled by 
% separately invoking sspropc with a single argument:
%
% sspropc -savewisdom      (save accumualted wisdom to file)
% sspropc -forgetwisdom    (forget accumualted wisdom)
% sspropc -loadwisdom      (load wisdom from file)
%
% The wisdom file (if it exists) is automatically loaded the
% first time sspropc is executed.
%
% The following four commands can be used to designate the planner
% method used by the FFTW routines in subsequent calls to
% sspropc.  The default method is patient.  These settings are
% reset when the function is cleared or when Matlab is
% restarted. 
%
% sspropc -estimate
% sspropc -measure
% sspropc -patient
% sspropc -exhaustive
%
% See also:  ssprop (equivalent matlab code)
%
% VERSION:  2.0.1
% AUTHOR:  Thomas E. Murphy (tem@umd.edu)

% THIS FILE CONTAINS NO MATLAB CODE, IT ONLY PROVIDES
% DOCUMENTATION FOR THE CORRESPONDING MEX FILE, sspropc.c  
% PLEASE CONSULT ssprop.m FOR A MATLAB SCRIPT WHICH PERFORMS
% THE SAME FUNCTIONS AS THIS COMPILED MEX PROGRAM.

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
