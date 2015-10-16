function [s,mantissa,factor,unit,exponent,prefix] = formatPrefixSI(x,numspec,unitspec,base,nonSI)

if nargin<5 % Use traditional units: c, d, da, h.
    nonSI = false;
end

if nargin<4 || isempty(base); % Reference base for the number (if not 10^0)
    base = 0;
elseif ~isscalar(base)
    error('Number base must be a real scalar');
elseif base
    base = log10(base);
end

if nargin<3 % Unit
    unitspec = '';
end

if nargin<2 || isempty(numspec) % Number format specification
    numspec = '%1.2f';
end

% Formats numbers with units
% E.g. 10e12 -> 10 T
if ~isscalar(x)
    error('Input number must be a scalar.');
elseif x==0 || isinf(x);
    exponent = 0;
else
    exponent = log10(x)+base;
end

if isnan(exponent)
    exponent = 0;
elseif exponent<-24
    exponent = -24;
end

EXPONENT = [-24 -21 -18 -15 -12  -9  -6  -3  -2  -1  0    1   2   3   6   9  12  15  18  21  24];
PREFIX   = {'y' 'z' 'a' 'f' 'p' 'n' 'u' 'm' 'c' 'd' '' 'da' 'h' 'k' 'M' 'G' 'T' 'P' 'E' 'Z' 'Y'};
if ~nonSI
    [~,idx] = intersect(EXPONENT,[-2 -1 1 2]);
    EXPONENT(idx) = [];
    PREFIX(idx) = [];
end

idx = find(EXPONENT<=exponent,1,'last');
exponent = EXPONENT(idx);

idx = find(EXPONENT==exponent,1);
prefix = PREFIX{idx};

factor = 10^(base-exponent);
mantissa = x*factor;
unit = [prefix unitspec];
s = sprintf([numspec ' ' unit],mantissa);
