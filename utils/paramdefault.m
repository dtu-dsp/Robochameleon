%> @file paramdefault.m
%> @brief Set default parameter values
%> 
%> @ingroup roboUtils
%> 
%> Helper function that defaults any param to a given value, in case it
%> doesn't exist. In case several params are present, it takes the last.
%>
%> @param param parameter structure to search in
%> @param keys strings to look for
%> @param value default value
%> 
%> @retval out Either user-specified or default value
%>
%> @see unit::setparams
%> @author Miguel Iglesias
function out = paramdefault( param, keys, value )

idx = isfield(param, keys);
if ~iscell(keys)
    keys = {keys};
end
keys = keys(idx);
if any(idx)
    out = param.(keys{end});
else
    out = value;
end
