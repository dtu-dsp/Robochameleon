classdef B < unit

    properties
        nInputs = 1;
        nOutputs = 1;
    end
    
    methods
        function obj = B(param)
        end
        
        function out = traverse(obj,in)
            out = in;
        end
    end
end