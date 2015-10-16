%> @file Combiner_v1.m
%> @brief Contains the implementation of a signal combiner utility.
%>
%> @class Combiner_v1
%> @brief Combines several signals into one with several colums.
%>
%> Set type to 'simple' to combine N signals to N columns, or 'complex' to
%> combine N signals to N/2 complex colums
%>
%> Example:
%> @code
%> combiner = Combiner_v1(2);
%> @endcode
%>
%> @see Splitter_v1
%>
%> @author Miguel Iglesias
%> @version 1
classdef Combiner_v1 < unit

    properties
        %> Number of input signals
        nInputs; 
        %> Number of output signals
        nOutputs = 1; 
        
        %> Combiner type {'simple' | 'complex'}
        type; 
    end
    
    methods
        %> @brief Class constructor
        %>
        %> @param type Combiner type {'simple' | 'complex'}
        %> @param nInputs number of inputs
        %> @return instance of the Combiner_v1 class
        function obj = Combiner_v1(type, nInputs)
            obj.type = type;
            if strcmp(obj.type, 'complex') && rem(nInputs,2) ~= 0
                robolog('For complex operation nInputs must be even', 'ERR');
            end
            obj.nInputs = nInputs;
        end
        
        %> @brief Traverse function
        %>
        %> @param varargin inputs
        %> @return out output
        function out = traverse(obj,varargin)
            out = obj.combine(varargin);
            if strcmp(obj.type, 'complex')
                out = obj.combineComplex(out);
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