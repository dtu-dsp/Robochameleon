%> @file arecells.m
%> @brief 
%> 
%> @ingroup roboUtils
%>
%> @brief Checks if all input variables are cell arrays
%> 
%> Helper function that checks if all input variables are cell arrays
%>
%> @param varargin multiple variable
%> 
%>
%> @author Rasmus Jones
function [y,bool] = arecells( varargin )
    N=length(varargin);
    bool=logical(zeros(1,N));
    for n=1:N
        bool(n)=iscell(varargin{n});
    end
    y=sum(bool)==N;
end