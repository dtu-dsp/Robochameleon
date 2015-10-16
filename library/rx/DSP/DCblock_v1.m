%> @file DCblock_v1.m
%> @brief DC block
%>
%> @class DCblock_v1
%> @brief DC block
%>
%> @ingroup stableDSP
%> @ingroup physModels
%> 
%> Blocks DC either by polarization or by channel
%>
%> @version 1
%> @author unclear
classdef DCblock_v1 < unit
    % Blocks DC either by polarization or by channel
    
    
    properties
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs  = 1;
        
        %> mode {channel | polarization}
        mode = 'channel';
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> @param param.mode  perform DC blocking per-polarization or over whole channel {'channel' | 'polarization'}
        function obj = DCblock_v1(param)
            if nargin<1, param = {}; end; obj.setparams(param);
        end
        
        %> @brief Main function
        function out = traverse(obj,in)
            
            switch obj.mode
                case 'channel'
                    out = in.fun1(@(x) obj.ComplexDCblock(x));
                case 'polarization'
                    out = in.fun1(@(x) x-mean(x));
                otherwise
                    warning('Mode not supported, using per channel DC blocking')
                    obj.mode = 'channel';
                    out = obj.traverse(in);
            end
        end
        
        %> @brief DC blocking for complex signals
        function out = ComplexDCblock(obj,in)
           in = [real(in) imag(in)];
           data = bsxfun(@minus,in,mean(in));
           out = data(:,1) + 1i*data(:,2);
        end
    end
    
end