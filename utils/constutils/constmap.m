function [map,demap] = constmap(consttype,M,maptype,usermap)
% CONSTMAP   Generates constellation mappings.
%
% MAP = CONSTMAP(CONSTTYPE,M,MAPTYPE[,USERMAP])
%
%   CONSTTYPE - constellation type (check types supported by constref)
%   M - constellation order
%   MAPTYPE - constellation map type; available:
%       'gray' Gray mapping
%       'user' User-defined mapping (used to generate demapping map)
%   USERMAP - user-provided map with M elements
%
%   Base-1 index is used for maps to simplify MATLAB code.
%   Example of use is in constutils_example.m
%
%   See also: constref
%
%   This function requires grays function from 'Gray Code Manipulation'
%   package available at http://www.mathworks.com/matlabcentral/fileexchange/15570-gray-code-manipulation
%
% Robert Borkowski, rbor@fotonik.dtu.dk
% Technical University of Denmark
% v1.0, 15 August 2014

switch lower(maptype)
    case {'linear', 'lin', 'binary', 'bin'}
        map = uint16(1:M)';
    case 'gray'
        seq = uint16(0:M-1)';
        map = bitxor(seq,bitshift(seq,-1))+1; % Generate Gray code
        if strcmpi(consttype,'qam')
            log2M = log2(M);
            if iswhole(log2M)
                for i=log2M:2*log2M:M
                    map(i+(1:log2M)) = map(i+(log2M:-1:1));
                end
            else
                robolog('Gray mapping for constellations with M~=2^k is undefined. Please work on 8-QAM.', 'ERR');
            end
        end
    
    case 'custom'
        if nargin<4
            robolog('For type ''custom'', a  custom map has to be provided.', 'ERR');
        elseif numel(usermap)~=M
            robolog('Number of elements in user map must be equal to modulation order', 'ERR');
        else
            map = uint16(usermap(:));
        end
end

[~,demap] = sort(map);
demap = uint16(demap);
demap_ = demap;

switch lower(consttype)
    case 'qam'
        if M == 32
            demap(:,end+1) = [1:1:M]; % This is not a Gray code! This change make this code compatible with TxSymbolsGen_v1.
        else
            log2M = log2(M);
            for i=1:3;
                demap(:,end+1) = reshape(rot90(reshape(demap_,2^(log2M/2),2^(log2M/2)),i),M,1);
            end
        end
    case 'psk'
        for i=1:M-1
            demap(:,end+1) = circshift(demap_,i);
        end
        
    case 'dpask'
         if ~rem(M,sqrt(M)) && M>1 % square constellation
             demap(:,end+1) = reshape(reshape(demap_,log2(M),log2(M)).',M,1);
         elseif M==8    %couldn't figure out how to do this elegantly, sorry Robert
             demap(:,end+1) = demap_([1, 5, 3, 7, 2, 6, 4, 8]);
%             demap = [ 1 1;
%                      ? ?
%                      2 2
%                      ? ?
%                      ? ?
%                      ? ?
%                      ? ?
%                      ? ? ];

         end
         
    case 'dpask-experimental'
        demap = [1 1
                 2 2
                 3 5
                 4 6
                 5 3
                 6 4
                 7 7
                 8 8 ];
%          demap = [demap [flipud(demap(1:4,:)); demap(5:8,:)]];
                 
    otherwise
        robolog('No demapping permutations generated.', 'WRN');
end
