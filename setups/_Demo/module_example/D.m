classdef D < unit

    properties
        nInputs = 1;
        nOutputs = 2;
    end
    
    methods
        function obj = D(param)
        end
        
        function [out1,out2] = traverse(obj,in)
            out1 = in;
            out2 = in;
        end
    end
end