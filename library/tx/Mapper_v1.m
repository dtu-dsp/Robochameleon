%> @file Mapper_v1.m
%> @brief implementation of a mapper
%>
%> @class Mapper_v1
%> @brief Mapper module
%>
%> This model maps an input binary signal in a modulation format
%> constellation.
%>
%>
%> @author Julio Diniz
%> @author Rasmus Jones
%> @author Simone Gaiarin
%>
%> @version 2
classdef Mapper_v1 < unit
    
    properties
        %> Symbol rate
        symbolRate = 1;
        %> Modulation order
        M;
        %> Modulation Format
        modulationFormat;
        %> Number of Modes (or polarizations)
        N = 1;
        %> Modulation constellation
        constellation;
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;
    end
    
    methods
        %>  @brief Class constructor
        %>
        %> @param param.M              Modulation order(s). Vector of size N, different modulation orders are allowed
        %>                             for different modes. If only one value is provided this will be used for all the modes.
        %> @param param.N              Number of modes. [Default: Length of M vector].
        %> @param param.modulationFormat    Modulation format. [Cell array of string e.g. {"QPSK", "QAM"}. If there is 
        %>                                  a single element this will be used for all the mode. (In this case it can also
        %>                                  be specified as string instead of single element cell.)
        %>                                  [Possible values: 'ASK', 'PSK', 'QAM', 'Custom'].
        %>                                  See constref.m also.
        %> @param param.symbolRate     Symbol rate. [Default: Undefined]
        %> @param param.constellation  Constellation (set of complex symbols). [Cell array of vectors of complex doubles.]
        %>                             Can be used to specify custom constellations, but usually should not be specified at all.
        %>                             If the i-th element is empty the constellation
        %>                             will be generated based on the i-th element of the modulationFormat and M arrays.
        %>                             If it's not empty the number of elements in the constellation must match the 
        %>                             corresponding element of the vector M.
        function obj = Mapper_v1(param)
            requiredParams = {'M','modulationFormat'};
            quietParams = {'constellation'};
            if ~isfield(param, 'N') && isfield(param, 'M')
                param.N = length(param.M);
            end
            obj.setparams(param,requiredParams,quietParams)
            
            if length(obj.M) ~= obj.N
                if length(obj.M) == 1
                    % Generate a vector M of length N replicating the single specified modulation order
                    obj.M = obj.M*ones(1,obj.N);
                else
                    robolog('You shall define "M" as a vector of length 1 or "N".', 'ERR')
                end
            end

            % Generate a vector modulationFormat of length N replicating the single specified modulation format
            if ~iscell(obj.modulationFormat) % We have a single string
                obj.modulationFormat = {obj.modulationFormat};
            end
            if obj.N > 1 % Only required if we have more than one mode
                if length(obj.modulationFormat) ~= obj.N % ..and the length of the modulation format is not N
                    if length(obj.modulationFormat) == 1
                        obj.modulationFormat = repelem(obj.modulationFormat(1), 1, obj.N);
                    else
                        robolog('modulationFormat must be a cell array of length 1 or "N". Example: {"QPSK", "16QAM"}.', 'ERR')
                    end
                end
            end

            % Check that the modulation orders are a power of 2
            if sum(mod(log2(obj.M),1) ~= 0)
                robolog('Modulation Order, M, should be a power of 2.', 'ERR');
            end
            
            n = length(obj.constellation);
            if  n < obj.N
                c = cell(1,obj.N);
                c(1:n) = obj.constellation;
                obj.constellation = c;
            end
            
            for ii = 1:obj.N
                if isempty(obj.constellation{ii})
                    if strcmpi(obj.modulationFormat{ii}, 'ask')
                        obj.constellation{ii} = constref('ask', obj.M(ii), 0);
                    elseif strcmpi(obj.modulationFormat{ii}, 'qam') && (mod(log2(obj.M(ii)),2) == 0)
                        obj.constellation{ii} = constref('qam', obj.M(ii), 0);
                    elseif strcmpi(obj.modulationFormat{ii}, 'psk')
                        obj.constellation{ii} = constref('psk', obj.M(ii), 0);
                    elseif ~strcmpi(obj.modulationFormat{ii}, 'custom')
                        robolog('Custom modulations are not implemented yet', 'ERR');
                    end
                else
                    if obj.M(ii) ~= numel(obj.constellation{ii})
                        robolog('The specified modulation order doesn''t match the number of symbols in the constellation %d', 'ERR', ii);
                    end
                end
            end
        end
        
        %> @brief Perform mapping of bits to symbol using grey coding
        %>
        %> Works properly only with constellation generated by constref.
        %>
        %> **results.txSymbolsIndices** Saves the transmitted constellation symbols indices (N columns)
        %>
        %> @param bitsSig signal_interface containing a logical matrix of size nSymbols x sum(log2(M)) with M vector
        %>                of modulation order for the different modes
        %>
        %> @retval symbolsSig signal_interface with N (number of modes) columns with the symbols
        function symbolsSig = traverse(obj, bitsSig)
            bits = bitsSig.getRaw();
            symbols = zeros(bitsSig.L,obj.N);
            indices = zeros(bitsSig.L,obj.N);
            for ii = 1:obj.N
                if ii == 1
                    last_in = 0;
                else
                    last_in = last_in + log2(obj.M(ii-1));
                end
                
                [symbols(:,ii), indices(:,ii)] = obj.grayMap(obj.constellation{ii}, ...
                    obj.modulationFormat{ii}, bits(:,last_in+1:last_in+log2(obj.M(ii))));
            end
            symbolsSig = signal_interface(symbols, struct('Rs', obj.symbolRate, 'Fs', obj.symbolRate));
            
            % Save results
            obj.results.txSymbolsIndices = indices;
        end
    end
    
    
    methods (Static)
        
        %> @brief Perform mapping of bits to symbol using gray coding
        %>
        %> If the modulation type is set to USR, a random mapping is performed based on the sorting
        %> of the input constellation.
        %>
        %> @param constellation Constellation. Set of complex symbols.
        %> @param modulationType Modulation type. [Possible values: 'PSK', 'ASK', 'QAM', 'USR']
        %> @param bits Bits to be mapped. Logical matrix of size nSymbols x log2(M). Least significant bit (LSB) on the right.
        %>
        %> @retval symbols Constellation symbols corresponding to the input bits
        %> @retval indexOut Indices of the INPUT constellation corresponding to the input bits (symbols = constellation(index))
        function [symbols, indexOut] = grayMap(constellation, modulationType, bits)
            M = numel(constellation);
            
            % Generate a map
            seq = uint16(0:M-1)';
            gray = bitxor(seq,bitshift(seq,-1))+1; % Generate Gray code
            % tx_symb = c(gray==data) not c(gray(data))
            % Performing this sorting we can use map as tx_symb = c(map(data))
            [~, map] = sort(gray);
            
            % Sort the input constellation symbols properly in order to achieve a proper Gray mapping
            % In this way we don't need to assume any sorting on the input constellation
            if strcmpi(modulationType, 'ask')
                [constSorted, scidx] = Mapper_v1.sortConstellationASK(constellation);
            elseif strcmpi(modulationType, 'psk')
                [constSorted, scidx] = Mapper_v1.sortConstellationPSK(constellation);
            elseif strcmpi(modulationType, 'qam')
                if mod(M, 2) == 0
                    [constSorted, scidx] = Mapper_v1.sortConstellationQAM(constellation);
                else
                    constSorted = constellation; % No sorting defined for non-squared QAM to perform proper gray mapping
                    robolog('No squared QAM constellation. Not gray mapped.', 'WRN');
                end
            else
                constSorted = constellation; % No sorting defined to perform proper gray mapping
                scidx = 1:M;
                robolog('This constellation doesn''t support gray mapping. Performed random mapping.');
            end
            
            bitsDec = 1 + bi2de(fliplr(bits)); % Convert bits to decimals + 1
            index = map(bitsDec); % Indices of the SORTED constellation corresponding to the input bits
            symbols = constSorted(index); % Output symbols
            symbols = symbols(:);
            indexOut = scidx(index); % Indices of the INPUT constellation corresponding to the input bits
        end
        
        %> @brief Sort the symbols of a PSK constellation in order to allow gray mapping
        %>
        %> The symbols are sorted by their phase. (In the range 0:2pi)
        %>
        %> @param constellation Constellation. Set of complex symbols.
        %>
        %> @retval constSorted Constellation mapped for grey coding
        %> @retval indices Map between input and output constellation (constSorted = constellation(indices))
        function [constSorted, indices] = sortConstellationPSK(constellation)
            % First sort the constellation according to the phases from 0 to 2pi
            ang = angle(constellation);
            ang(ang<0) = 2*pi + ang(ang<0);
            [~, indices] = sort(ang);
            constSorted = constellation(indices);
        end
        
        %> @brief Sort the symbols of a ASK constellation in order to allow gray mapping
        %>
        %> The symbols are sorted by their real part.
        %>
        %> @param constellation Constellation. Set of complex symbols.
        %>
        %> @retval constSorted Constellation mapped for grey coding
        %> @retval indices Map between input and output constellation (constSorted = constellation(indices))
        function [constSorted, indices] = sortConstellationASK(constellation)
            [constSorted, indices] = sort(constellation);
        end
        
        %> @brief Sort the symbols of a QAM constellation in order to allow gray mapping
        %>
        %> For square QAM we need to flip upside down the even columns.
        %> in order to produce the correct gray mapping.
        %> The gray codewords are assigned to the symbols starting from the top left corner
        %> of the constellation and going down. Once at the bottom we proceed by going up
        %> the next column and so on. See Wikipedia.
        %>
        %> Sort the constellation symbols as follow:
        %> 1 8 9 .
        %> 2 7 . .
        %> 3 6 . .
        %> 4 5 . .
        %> @param constellation Constellation. Set of complex symbols.
        %>
        %> @retval constSorted Constellation mapped for grey coding
        %> @retval indices Map between input and output constellation (constSorted = constellation(indices))
        function [constSorted, indices] = sortConstellationQAM(constellation)
            % First sorting from an arbitrarly unsorted constellation
            %> 1 5 9 .
            %> 2 6 . .
            %> 3 7 . .
            %> 4 8 . .
            c = [real(constellation(:)) imag(constellation(:))];
            [~, indices] = sortrows(c, [1 -2]);
            
            % Flip even columns up down
            M = numel(constellation);
            indices = reshape(indices, sqrt(M), sqrt(M)); % Make constellation squared
            indices(:,2:2:end) = flipud(indices(:,2:2:end)); % Flip even columns up-down
            indices = indices(:);
            
            % Output sorted constellation
            constSorted = constellation(indices);
        end
    end
end
