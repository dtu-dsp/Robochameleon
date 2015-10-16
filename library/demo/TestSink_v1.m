%>@file TestSink_v1.m
%>@brief Dummy receiver
%> 
%>@class TestSink_v1
%>@brief  Dummy receiver
%>
%> Prints input data to workspace
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