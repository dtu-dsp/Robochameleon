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
%> @author Júlio Diniz, Rasmus Jones
%> @version 2
classdef Mapper_v1 < unit
    
    properties
        %>  Number of inputs
        nInputs = 1;
        %>  Number of outputs
        nOutputs = 1;
        %> Number of Modes (or polarizations)
        N = 1;
        %> Modulation order
        M;
        %>  Modulation Format
        modulationFormat;
        %>  Modulation constellationMap
        constellationMap;
        
    end
    
    methods
        %>  @brief Class constructor
        function obj = Mapper_v1(param)
            obj.setparams(param,{'M','modulationFormat'},{'N','constellationMap'})
            
            if length(obj.M) ~= obj.N
                if length(obj.M) == 1
                    obj.M = obj.M*ones(1,obj.N);
                else
                    robolog('You shall define modulation order ("M") with length equal to 1 or number of modes ("N").', 'ERR')
                end
            end

            if iscell(obj.modulationFormat) && (length(obj.modulationFormat) ~= obj.N) && (length(obj.modulationFormat) ~= 1)
                robolog('You shall define same number of modulation formats as number of modes, using an cell of arrays. Example: {"QPSK", "16QAM"}', 'ERR')
            else
                if iscell(obj.modulationFormat) && (length(obj.modulationFormat) == 1)
                    obj.modulationFormat = obj.modulationFormat{1};
                end
                if ~iscell(obj.modulationFormat) || (iscell(obj.modulationFormat) && (length(obj.modulationFormat) == 1))
                    auxvar = cell(1,obj.N);
                    for ii = 1:obj.N
                        auxvar{ii} = obj.modulationFormat;
                    end
                    obj.modulationFormat = auxvar;
                end
            end              

            if sum(mod(log2(obj.M),1) ~= 0)
                robolog('Modulation Order, M, should be a power of 2: e.g. 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, ...', 'ERR');
            end
            
            for ii = 1:obj.N
                if strcmpi(obj.modulationFormat{ii}, 'qam') && (mod(log2(obj.M(ii)),2) == 0)
                    obj.constellationMap{ii} = constref('qam', obj.M(ii), 0);
                elseif strcmpi(obj.modulationFormat{ii}, 'psk')
                    obj.constellationMap{ii} = constref('psk', obj.M(ii), 0);
                elseif ~strcmpi(obj.modulationFormat{ii}, 'custom')
                    obj.constellationMap{ii} = constref(obj.modulationFormat{ii}, obj.M(ii), 0);
                end
                obj.constellationMap{ii} = obj.constellationMap{ii}/max(max(abs([real(obj.constellationMap{ii}) ; imag(obj.constellationMap{ii})])));
            end
        end
        
        %>  @brief Main function
        
        function out = traverse(obj,in)
            bits = in.E;
            symbols = zeros(max(size(bits)),obj.N);
            for ii = 1:obj.N
                if ii == 1
                    last_in = 0;
                else
                    last_in = last_in + log2(obj.M(ii-1));
                end
                
                if strcmp(obj.modulationFormat{ii}, 'qam') && (mod(log2(obj.M(ii)),2) == 0)
                    constMapped  = obj.reMapQAM(obj,ii); % Needed to do this due to constref().
                else
                    constMapped = obj.constellationMap{ii};
                end
                symbols(:,ii) = obj.grayMap(log2(obj.M(ii)), constMapped, bits(:,last_in+1:last_in+log2(obj.M(ii))));
            end
            out = signal_interface(symbols, struct('Rs', 1, 'Fs', 1, 'P', pwr(inf, 10*log10(1)), 'Fc', 0));
        end
    end
    
    
    methods (Static)
        
        function symbols = grayMap(N, constellationMap, bits)
            a = cell(1, N);
            for ii = 1:N
                a{ii} = bits(:,ii);
            end
            for ii = 1:N-1
                a{ii+1} = xor(a{ii}, a{ii+1});
            end
            index =   [a{1:N}]*(2.^(0:N-1))';
            symbols = constellationMap(index+1);
            symbols = symbols(:);
        end
        
        function constMapped = reMapQAM(obj,ii) 
            for jj = 1:sqrt(obj.M)
                if mod(jj,2)
                    constMapped((jj-1)*sqrt(obj.M)+1:jj*sqrt(obj.M)) = obj.constellationMap{ii}((jj-1)*sqrt(obj.M)+1:jj*sqrt(obj.M));
                else
                    constMapped((jj-1)*sqrt(obj.M)+1:jj*sqrt(obj.M)) = obj.constellationMap{ii}(jj*sqrt(obj.M):-1:(jj-1)*sqrt(obj.M)+1);
                end
            end
        end
        
    end
end

