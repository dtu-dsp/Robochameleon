%> @file genTimeAxisSig.m
%> @brief Generate a time axis from signal_interface parameters
%>
%> __Example:__
%> @code
%> %s1 is a signal_interfaces
%> t = genTimeAxisSig(s1, 'central');
%> @endcode
%>
%> @author Simone Gaiarin
%>
%> @version 1

%>@brief Generate a time axis from signal_interface parameters
%>
%> @param sig signal_interface signal
%> @param varargin{1} Plot around zero. Possible values {'central'}
%>
%> @retval t A time axis based on Rs and Fs
function t = genTimeAxisSig( sig, varargin )
    offset = 0;
    if ~isempty(varargin)
        if strcmp(varargin{1}, 'central')
            offset = 0.5;
        end
    end
    Fs = sig.Fs;
    Rs = sig.Rs;
    if isinf(Rs)
        error('Rs must be defined');
    end
    Nss = Fs/Rs;
    Nsym = size(sig.get, 1)/Nss;
    t = -offset*Nsym*1/Rs:1/Fs:(1-offset)*Nsym*1/Rs - 1/Fs;
end
