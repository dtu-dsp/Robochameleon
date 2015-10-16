%> @file Negator_v1.m
%> @brief Negates the input
%> 
%> @class Negator_v1
%> @brief  Negates the input
%>
%> @author Miguel Iglesias
classdef Negator_v1 < unit
    
    properties
        nInputs = 1;
        nOutputs = 1;
    end
    
    methods
        function out = traverse(obj, sig)
            out = sig.fun1(@(x) 2*mean(x) - x);
        end
    end
    
end

