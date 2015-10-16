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
