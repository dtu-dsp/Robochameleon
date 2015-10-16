function [symb,dist] = hd_euclid(X,c)
% Euclidean metric hard decision digital demodulation
%
% SYMB = DD_HARD(X,C)
%
%   X - input constellation points
%   C - reference constellation
%   SYMB - demodulated symbols
%
% Robert Borkowski, rbor@fotonik.dtu.dk
% Technical University of Denmark
% v2.0, 15 August 2014

[dist,symb] = min(abs(bsxfun(@minus,X(:).',c(:))));
symb = uint16(symb(:));
dist = dist(:);
