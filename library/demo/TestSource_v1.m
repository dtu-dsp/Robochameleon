%> @file  TestSource_v1.m
%> @brief Simple "transmitter" that generates a dummy output signal

%> @class  TestSource_v1
%> @brief Simple "transmitter" that generates a dummy output signal
%>
%> For use in examples and function testing
%>
%> Signal is populated with random numbers
%> 
%> @see Demo setup supermimo
%>
%> @version 1
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
