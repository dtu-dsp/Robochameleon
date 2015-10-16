%> @file IQIdeal_v1.m
%> @brief Ideal IQ modulator model
%> 
%> @class IQIdeal_v1
%> @brief  Ideal IQ modulator model
%>
%> @author Miguel Iglesias
classdef IQIdeal_v1 < unit
    
    properties
        nInputs = 2;
        nOutputs = 1;
    end
    
    methods
        function out =  traverse(obj, in1, in2)
            out = in1.plus(in2.fun1(@(x) 1i*x));
        end
    end
    
end

