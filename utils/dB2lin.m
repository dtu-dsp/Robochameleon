%> @file dB2lin.m
%> @brief Convert dB to linear units
%>
%> @author Robert Borkowski
%>
%> @see pwr, defaultargs
%>
%> @version 1

%> @brief Convert dB to linear units
%>
%> @param dB          Input power in dB 
%> @param type        What dB is relative to [Watts:'db', mW:'dbm', uW:'dbu']; [default: dBW]
%>
%> @retval lin        Input in linear units
function lin = dB2lin(dB,varargin)

[type] = defaultargs({'db'},varargin);

switch lower(type)
    case 'db'
        fact = 0;
    case 'dbm'
        fact = -30;
    case 'dbu'
        fact = -60;
    otherwise
        error('Conversion type can be ''dB'', ''dBm'', ''dBu''.')
end

lin = 10.^((dB+fact)/10);
