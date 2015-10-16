%> @file constref.m
%> @brief Constellation reference
%>
%> 
%>   This function returns regular reference constellations that can be
%>   easily parameterized.
%>
%>  __Usage__
%>
%>@code
%>   [c, P] = constref(type, M, ROT)
%>@endcode
%>
%>@param type constellation type {'ASK','QAM','PSK','star','DPASK'}\n
%> type can also be {'OOK','PAM','QPSK','16-QAM'} for fast reference, and
%> is not case-sensitive.
%> 
%> @param M constellation order (number of points/levels).
%>           M must be an integer such that:\n
%>           - for 'QAM', M={k^2|k>1 && k integer,8,32,60}\n
%>           - for 'star', M=8
%>
%> @param ROT constellation rotation in degrees
%>           
%> @retval  c - complex constellation
%> @retval P average constellation energy (scaling factor)
%>           use c/sqrt(P) for normalization
%>
%>  __Conventions__
%>
%>   Clusters for square QAM are returned in the following order:
%> 
%>@verbatim
%>         Q(j)
%>    1  5 |  9 13
%>    2  6 | 10 14
%>   ------+------- I
%>    3  7 | 11 15
%>    4  8 | 12 16
%>@endverbatim
%>
%> Clusters for PSK are returned in the following order (first point always has phase of 0):
%>
%>@verbatim 
%>        Q(j)
%>         3 
%>      4  |  2
%>   -5----+----1- I
%>      6  |  8
%>         7 
%>@endverbatim
%>
%>
%> Clusters for DP-ASK are returned in the following order:
%>
%>@verbatim 
%>   Py
%>   | 4  8 12 16
%>   | 3  7 11 15
%>   | 2  6 10 14
%>   | 1  5  9 13
%>   +------------ Px
%>@endverbatim
%>
%> @see constmap.m
%>
%> @author Robert Borkowski 15.8.2014
%> @version v3.0b
function [c,P] = constref(type,M,varargin)

switch lower(type)
    case {'ask' 'pam'}
        c = 0:M-1;
        
    case 'qam'
        if ~rem(M,sqrt(M)) % square constellation
            X = 1-sqrt(M):2:sqrt(M)-1;
            [I,Q] = meshgrid(X);
            c = I+1j*Q;
            c = flipud(c);
        elseif M==8
            c = constref('QAM',16);
            mask = [ 0 0 0 0
                     1 1 1 1
                     1 1 1 1
                     0 0 0 0 ];
            c = c(logical(mask(:)));
        elseif M==12
            c = constref('QAM',16);
            mask = [ 0 1 1 0
                     1 1 1 1
                     1 1 1 1
                     0 1 1 0 ];
            c = c(logical(mask(:)));
        elseif M==32
            c = constref('QAM',36);
            mask = [ 0 1 1 1 1 0
                     1 1 1 1 1 1
                     1 1 1 1 1 1
                     1 1 1 1 1 1
                     1 1 1 1 1 1
                     0 1 1 1 1 0 ];
            c = c(logical(mask(:)));
        elseif M==60
            m = 64; sqrtm = 8;
            c = constref('QAM',m);
            mask = ones(sqrtm,sqrtm);
            mask([1 sqrtm m-[1 sqrtm]+1]) = 0;
            c = c(logical(mask(:)));
        else
            error('Constellation order not supported.');
        end
    
    case 'psk'
        c = exp(2j*pi*(0:M-1)/M);
    
    case 'star'
        if M==8
            c = [constref('PSK',4,45);2*constref('PSK',4)];
        else
            error('Constellation order not supported.');
        end
        
    % Dual polarization ASK in Px-Py plane (intensity X vs. intensity Y)
    % Redefine real(I)->Px, imag(Q)->Py.
    case 'dpask'
        if ~rem(M,sqrt(M)) % square constellation
            X = 0:sqrt(M)-1;
            [Px,Py] = meshgrid(X);
            c = Px+1j*Py;
        elseif M==8
            c = constref('DPASK',16);
            mask = [ 0 1 0 1
                     1 0 1 0
                     0 1 0 1
                     1 0 1 0 ];
            mask = flipud(mask);
            c = c(logical(mask(:)));
        else
            error('Constellation order not supported.');
        end
    
    % Special cases
    case 'ook'
        c = constref('ASK',2);
    case 'qpsk'
        c = constref('QAM',4);
    case '16-qam'
        c = constref('QAM',16);
           
    otherwise
        error('Constellation type not supported.');
end

rot = defaultargs(0,varargin);
c = c(:).*exp(1j*deg2rad(rot));
P = pwr.meanpwr(c);
