%> @file hd_euclid.m
%> @brief Minimun euclidean distance symbol decisor
%>
%> @author Robert Borkowski <rbor@fotonik.dtu.dk>
%> @version 1

%> @brief Euclidean metric hard decision digital demodulation
%>
%> To output is returned as unit16 by default. To get the output as double
%> call the function as follow.
%> @code
%> out = double(hd_euclid(X, c));
%> @endcode
%>
%> @param X Data to be decided, complex symbols
%> @param c Constellation, complex symbols (vector)
%>
%> retval symb Demodulated symbols [unint16]
%> retval dist Distance of the symbols form the closest point in the reference constellation
function [symb,dist] = hd_euclid(X, c)
% Euclidean metric hard decision digital demodulation

[dist,symb] = min(abs(bsxfun(@minus,X(:).',c(:))));
symb = uint16(symb(:));
dist = dist(:);
