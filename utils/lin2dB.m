%> @file lin2dB.m
%> @brief Convert linear units to dB
%>
%> @author Robert Borkowski
%>
%> @see pwr, defaultargs
%>
%> @version 1

%> @brief Convert linear units to dB
%>
%> @param lin         Input power in linear units
%> @param type        What dB is relative to [Watts:'db', mW:'dbm', uW:'dbu']; [default: dBW]
%>
%> @retval dB         Input in dB
function dB = lin2dB(lin,varargin)

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

dB = 10*log10(lin)-fact;
