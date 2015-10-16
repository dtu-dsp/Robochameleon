%> @file setParamFsRssNss.m
%> @brief Utility function to compute the missing parameter among Fs, Rs, Nss in a param structure
%>
%> @brief Given two fields among Fs, Rs, Nss, computes the missing one and sets it in the param structure
%>        
%> @param inParam           Input structure containing constructor parameters, which contains 
%>                          two of the fields among Fs, Rs, Nss.
%> 
%> @retval param            Output structure containing constructor parameters, which contains 
%>                          all the fields among Fs, Rs, Nss
function param = setParamFsRssNss(inParam)
    param = inParam;
    if isfield(inParam, 'Fs') && isfield(inParam, 'Rs') && isfield(inParam, 'Nss')
        robolog('All Fs, Rs, Nss are already defined. Nothing to do.');
    elseif isfield(inParam, 'Fs') && isfield(inParam, 'Nss')
        param.Rs = param.Fs/param.Nss;
    elseif isfield(inParam, 'Fs') && isfield(inParam, 'Rs')
        param.Nss = param.Fs/param.Rs;
    elseif isfield(inParam, 'Rs') && isfield(inParam, 'Nss')
        param.Fs = param.Rs*param.Nss;
    else
        robolog('You need to specify at least two value among Fs, Rs, Nss', 'ERR');
    end        
end