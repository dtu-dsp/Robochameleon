%> @file  TestCh2x2_v1.m
%> @brief Simple "channel" that passes two inputs to two outputs

%> @class  TestCh2x2_v1
%> @brief Simple "channel" that passes two inputs to two outputs
%>
%> For use in examples and function testing
%>
%> Adds a DC offset to both channels so that user can verify channel has
%> been traversed.
%> 
%> @see Demo setup supermimo
%>
%> @version 1
classdef TestCh2x2_v1 < unit
    
    properties
        nOutputs = 2;
        nInputs = 2;
    end
    
    methods
        function [out1,out2] = traverse(obj,in1,in2)
            out1 = signal_interface(get(in1)+.01,struct('Fs',1,'Rs',1, 'Fc', 0, 'P', pwr(inf, 0)));
            out2 = signal_interface(get(in2)+.02,struct('Fs',1,'Rs',1, 'Fc', 0, 'P', pwr(inf, 0)));
            fprintf('Traversing channel\n');
            obj.results = 'qqwewqe';
        end
    end
end