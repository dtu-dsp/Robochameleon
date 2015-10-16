classdef A < unit

    properties
        nInputs = 1;
        nOutputs = 1;
    end
    
    methods
        function obj = A(param)
        end
        
        function out = traverse(obj,in)
            out = in;
        end
    end
end