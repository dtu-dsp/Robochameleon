classdef C < unit

    properties
        nInputs = 2;
        nOutputs = 3;
    end
    
    methods
        function obj = C(param)
        end
        
        function [out1,out2,out3] = traverse(obj,in1,in2)
            out1 = in1;
            out2 = in2;
            out3 = in2;
        end
    end
end