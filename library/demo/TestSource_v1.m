%>@file TestSource_v1.m
%>@brief Dummy transmitter
%> 
%>@class TestSource_v1
%>@brief  Dummy transmitter
%>
%> Generates random signal_interface 
classdef TestSource_v1 < unit

    properties (Hidden=true)
        nInputs = 0; % Number of input arguments
        nOutputs = 1; % Number of output arguments
    end

    methods
        
        function out1 = traverse(obj)
            out1 = signal_interface((1:10)+round(10*rand),struct('Fs',1,'Rs',1, 'Fc', 0, 'P', pwr(inf, 0)));
            fprintf(1,'Traversing source\n');
            
            % Save all results inside obj.results
            obj.results = 'q';
        end
    end
end
