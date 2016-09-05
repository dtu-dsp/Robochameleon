%> @file ChannelCombiner_v1.m
%> @brief Combines signals with different carrier frequency

%>@class ChannelCombiner_v1
%>@brief Combines signals with different carrier frequency
%>
%> This unit combines signals of with different carrier frequency into one
%> signal. The outgoing carrier frequency is centered among the input
%> signals.
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef ChannelCombiner_v1 < unit
    
    properties
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;
    end
    
    methods (Static)
        
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Constructs an object of type ChannelCombiner_v1.
        %>
        %> @param param.nInputs          Number of inputs.
        %> @param param.nOutputs         Number of outsputs.
        %>
        %> @retval obj      An instance of the class ChannelCombiner_v1
        function obj = ChannelCombiner_v1(param)
            obj.setparams(param);
        end
        
        %> @brief Brief description of what the traverse function does
        %>
        %> @param in    The signal_interface of the input signals of different wavelength
        %>
        %> @retval out  The signal_interface of the combined signal
        function out = traverse(obj, varargin)
            N=obj.nInputs;
            Fc=zeros(1,N);
            Fc(1) = varargin{1}.Fc;
            Fs=varargin{1}.Fs;

            if N ~= length(varargin)
                robolog('Number of inputs not equal to the number of signal interfaces.', 'ERR')
            end
            
            for ii=2:N
                Fc(ii) = varargin{ii}.Fc;
                if Fs ~= varargin{ii}.Fs;
                    robolog('Sample frequency of all channels have to coincide.', 'ERR')
                end
            end
            [~,ii]=max(Fc);
            % TODO check with obw

            out=varargin{1};
            for ii=2:N
                out = out + varargin{ii};
                Fc(ii) = varargin{ii}.Fc;
            end
            %Center signal at center frequency
            df = out.Fc-(max(Fc)+min(Fc))/2;
            out = fun1(out, @(x)x.*exp(2i*pi*df/out.Fs*(0:out.L-1)'));
            out = out.set('Fc',(max(Fc)+min(Fc))/2);
        end
    end
end
