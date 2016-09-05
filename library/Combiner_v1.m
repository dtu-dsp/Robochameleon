%> @file Combiner_v1.m
%> @brief Contains the implementation of a signal combiner utility.
%>
%> @class Combiner_v1
%> @brief Combines several signals into one with several colums.
%>
%> Set type to 'simple' to combine N signals to N columns, or 'complex' to
%> combine N signals to N/2 complex colums
%>
%> __Example__
%> @code
%>   param.cb.nInputs = 2;
%>   param.cb.type = 'simple';
%>  combiner = Combiner_v1(param.cb);
%> @endcode
%>
%> @see Splitter_v1
%>
%> @author Miguel Iglesias
%> @author Simone Gaiarin
%>
%> @version 1
classdef Combiner_v1 < unit
    
    properties
        %> Number of input signals
        nInputs;
        %> Number of output signals
        nOutputs = 1;
        
        %> Combiner type {'simple' | 'complex' | 'add' | 'complexInterleave'}
        type;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> @param param.type Combiner type {'simple' | 'complex'}
        %> @param param.nInputs Number of inputs
        function obj = Combiner_v1(varargin)
            if length(varargin) > 1
                param.type = varargin{1};
                param.nInputs = varargin{2};
                robolog('This interface is deprecated and will be removed. Pass a struct with parameters instead.', 'WRN');
            else
                param = varargin{1};
            end
            
            if strcmp(obj.type, 'complex') && rem(param.nInputs,2) ~= 0
                robolog('For complex operation nInputs must be even', 'ERR');
            end
            if strcmp(obj.type, 'complexInterleave') && param.nInputs ~= 2
                robolog('For complex interleaving operation nInputs must be two', 'ERR');
            end
            obj.setparams(param);
        end
        
        %> @brief Traverse function
        %>
        %> @param varargin inputs
        %> @return out output
        function out = traverse(obj,varargin)
            switch obj.type
                case 'simple'
                    out = obj.combine(varargin);
                case 'complex'
                    out = obj.combine(varargin);
                    out = obj.combineComplex(out);
                case 'add'
                    out = varargin{1};
                    for jj = 2:nargin-1
                        out = out + varargin{jj};
                    end
                case 'complexInterleave'
                    out = varargin{1} + varargin{2}*1i;
            end
        end
    end
    
    methods (Static)
        %> @brief Concatenates signals
        %>
        %> Takes a cell array of signal_interfaces and combines them into
        %> one with N colums
        function out = combine(in)
            Combiner_v1.CheckInputs(in);
            Nelem = cellfun(@(x)x.N, in);       %cellfun(@(x)x.N, in) returns an array with each signal's number of elements
            data = zeros(in{1}.L, sum(Nelem));
            for i=1:length(in)
                %data(i) = in{i}.get;       %OLD
                %Pcol(i)=in{i}.P;           %OLD
                data(:,sum(Nelem(1:i-1))+(1:Nelem(i))) = in{i}.get;        %NEW
                Pcol(sum(Nelem(1:i-1))+(1:Nelem(i)), 1) = in{i}.PCol(:);        %NEW
            end
            %out = in{1}.set(data);
            out = signal_interface(data, struct('Rs', in{1}.Rs, 'Fs', in{1}.Fs, 'Fc', in{1}.Fc, 'PCol', Pcol));
        end
        
        %> @brief Makes signals complex and concancatenates them
        %>
        %> Takes one signal_interface with 4 columns and combines them into
        %> one signal_interface with 2 complex colums
        function out = combineComplex(sig)
            data = sig.get;
            dataNew = zeros([sig.L, sig.N/2]);
            for i=1:(sig.N/2)
                dataNew(:,i) = data(:,(i-1)*2+1) + 1i*data(:,(i-1)*2+2);
                Pcol(i) = sig.PCol((i-1)*2+1)+sig.PCol((i-1)*2+2);
            end
            %out = sig.set(dataNew);
            out = signal_interface(dataNew, struct('Rs', sig.Rs, 'Fs', sig.Fs, 'Fc', sig.Fc, 'PCol',Pcol));
        end
        
        %> @brief Checks inputs
        %>
        %> Takes a cell array of signal_interface and makes sure relevant
        %> parameters match
        function CheckInputs(in)
            Rs =cellfun(@(x)x.Rs, in);
            if numel(unique(Rs))>1, robolog('Symbol rates must be equal', 'ERR'); end
            Fs =cellfun(@(x)x.Fs, in);       %cellfun(@(x)x.N, in) returns an array with each signal's number of elements
            if numel(unique(Fs))>1, robolog('Sample rates must be equal', 'ERR'); end
            L =cellfun(@(x)x.L, in);       %cellfun(@(x)x.N, in) returns an array with each signal's number of elements
            if numel(unique(L))>1, robolog('Waveform lengths', 'ERR'); end
        end
    end
end
