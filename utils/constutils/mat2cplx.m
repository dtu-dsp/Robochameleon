function x = mat2cplx(y)
%MAT2CPLX   Converts a matrix to a complex vector.
%
%   X = MAT2CPLX(Y)

if size(y,2)~=2
    error('Second dimension must be 2.');
end
if ~isreal(y)
    error('Only reals allowed.');
end

x = complex(y(:,1),y(:,2));
