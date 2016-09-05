%> @file minIdx.m
%> @brief 
%> 
%> @ingroup roboUtils
%>
%> @brief Returning id instead of value of min()
%> 
%> Helper function returning id instead of value of min()
%>
%> @param varargin multiple variable
%> 
%>
%> @author Rasmus Jones
function id = minIdx( x,dim )
    [~,id]=min(x,[],dim);
end