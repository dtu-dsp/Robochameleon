function tf = iswhole(x,tol)

if nargin<2
    tol = 0;
end

if abs(x-fix(x))<=tol
    tf = true;
else
    tf = false;
end
