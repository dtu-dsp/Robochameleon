function y = combvec(varargin)
%COMBVEC Create all combinations of vectors.
%
%  Syntax
%
%    combvec(a1,a2,...)
%
%  Description
%
%    COMBVEC(A1,A2,...) takes any number of inputs,
%      A1 - Matrix of N1 (column) vectors.
%      A2 - Matrix of N2 (column) vectors.
%    and returns a matrix of (N1*N2*...) column vectors, where the columns
%    consist of all possibilities of A2 vectors, appended to
%    A1 vectors, etc.
%
%  Example
%  
%    a1 = [1 2 3; 4 5 6];
%    a2 = [7 8; 9 10];
%    a3 = combvec(a1,a2)

% Mark Beale, 12-15-93
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2005/12/22 18:19:12 $

if length(varargin) == 0
  y = [];
else
  y = varargin{1};
  for i=2:length(varargin)
    z = varargin{i};
    y = [copy_blocked(y,size(z,2)); copy_interleaved(z,size(y,2))];
end
end

%=========================================================
function b = copy_blocked(m,n)

[mr,mc] = size(m);
b = zeros(mr,mc*n);
ind = 1:mc;
for i=[0:(n-1)]*mc
  b(:,ind+i) = m;
end
%=========================================================

function b = copy_interleaved(m,n)

[mr,mc] = size(m);
b = zeros(mr*n,mc);
ind = 1:mr;
for i=[0:(n-1)]*mr
  b(ind+i,:) = m;
end
b = reshape(b,mr,n*mc);
