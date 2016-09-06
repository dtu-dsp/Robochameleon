%> @file iswhole.m
%> @brief Determine whether or not input is a whole number
%>
%> @version 1

%> @brief Determine whether or not input is a whole number
%>
%> @param x         Input number
%> @param tol       Tolerance [Default: 0]
%>
%> @retval tf       Boolean indicating whether or not input is a whole number
function tf = iswhole(x,tol)

if nargin<2
    tol = 0;
end

if abs(x-fix(x))<=tol
    tf = true;
else
    tf = false;
end
