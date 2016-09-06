%> @file  TestSink_v1.m
%> @brief Simple "receiver" that prints the input to the command window

%> @class  TestSink_v1
%> @brief Simple "receiver" that prints the input to the command window
%>
%> For use in examples and function testing
%> 
%> @see Demo setup supermimo
%>
%> @version 1
classdef TestSink_v1 < unit
    properties (Hidden=true)
        nInputs = 1;
        nOutputs = 0;
    end
    
    methods
        
        function traverse(obj,in)
            obj.results = 'q';
            fprintf(1,'Traversing sink\n');   
            get(in)
        end
    
    end
end