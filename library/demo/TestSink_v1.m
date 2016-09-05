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