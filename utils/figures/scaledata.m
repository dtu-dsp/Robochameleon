function Y = scaledata(X,minval,maxval)
%
% Program to scale the values of a matrix from a user specified minimum to a user specified maximum
%
% Usage:
% outputData = scaledata(inputData,minVal,maxVal);
%
% Example:
% a = [1 2 3 4 5];
% a_out = scaledata(a,0,1);
% 
% Output obtained: 
%            0    0.1111    0.2222    0.3333    0.4444
%       0.5556    0.6667    0.7778    0.8889    1.0000
%
% Program written by:
% Aniruddha Kembhavi, July 11, 2007
% Extended by:
% Robert Borkowski, July 19, 2012

if nargin<3
    maxval = 1;
else
    maxval = double(maxval);
end
if nargin<2
    minval = 0;
else
    minval = double(minval);
end

Y = X - min(X(:));
Y = (Y/range(Y(:)))*(maxval-minval);
Y = Y + minval;