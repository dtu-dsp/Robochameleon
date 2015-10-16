%>@file TestCh2x2_v1.m
%>@brief Dummy 2x2 channel
%> 
%>@class TestCh2x2_v1
%>@brief  Dummy 2x2 channel
%>
%> Input waveforms are the same as the output waveforms, with new 
%> signal_interface properties
classdef TestCh2x2_v1 < unit
    
    properties
        nOutputs = 2;
        nInputs = 2;
    end
    
    methods
        function [out1,out2] = traverse(obj,in1,in2)
            out1 = signal_interface(get(in1),struct('Fs',1,'Rs',1, 'Fc', 0, 'P', pwr(inf, 0)));
            out2 = signal_interface(get(in2),struct('Fs',1,'Rs',1, 'Fc', 0, 'P', pwr(inf, 0)));
            fprintf('Traversing channel\n');
            obj.results = 'qqwewqe';
        end
    end
end