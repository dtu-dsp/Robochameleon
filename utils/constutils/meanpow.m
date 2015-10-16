function [Pav,E,Prange] = meanpow(x)
%POW   Mean signal power and energy
%
%   [P,E] = POW(X)
%   P - signal power
%   E - signal energy
%   X - complex or real input signal
%
%   Robert Borkowski

warning('Please use meanpwr static function from pwr class -- change meanpow(*) to pwr.meanpwr(*). This function will be removed soon.');

absxsq = abs(x).^2;
L = size(x,1);
if L==1 %TODO what if size is 0
    L = size(x,2);
end
E = sum(absxsq);
Pav = E/L;
Prange = findrange(absxsq);
