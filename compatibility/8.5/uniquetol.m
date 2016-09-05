function [z,ii,jj] = uniquetol(x,tol,varargin)
%UNIQUETOL Unique element within a tolerance.
%   [Y,I,J] = UNIQUETOL(X,TOL) is very similar to UNIQUE, but allows an
%   additional tolerance input, TOL. TOL can be taken as the total absolute
%   difference between similar elements. TOL must be a none negative
%   scalar. If not provided, TOL is assumed to be 0, which makes UNIQUETOL
%   identical to UNIQUE.
%
%   UNIQUETOL(...,'ROWS')
%   UNIQUETOL(...,'FIRST')
%   UNIQUETOL(...,'LAST')
%   These expressions are identical to the UNIQUE counterparts.
%
%   See also UNIQUE.

% Siyi Deng; 03-19-2010; 05-15-2010; 10-29-2010;

if size(x,1) == 1, x = x(:); end
if nargin < 2 || isempty(tol) || tol == 0
    [z,ii,jj] = unique(x,varargin{:});
    return;
end
[y,ii,jj] = unique(x,varargin{:});
if size(x,2) > 1
    [~,ord] = sort(sum(x.^2,1),2,'descend');
    [y,io] = sortrows(y,ord);
    [~,jo] = sort(io);
    ii = ii(io);
    jj = jo(jj);
end
d = sum(abs(diff(y,1,1)),2);
isTol = [true;d > tol];
z = y(isTol,:);
bin = cumsum(isTol); % [n,bin] = histc(y,z);
jj = bin(jj);
ii = ii(isTol);

end % UNIQUETOL;









