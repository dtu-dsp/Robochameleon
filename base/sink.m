%> @file  sink.m
%> @brief Stores the input signal.
%>
%> @class  sink
%> @brief Stores the input signal.
%>
%> Utility unit used in module.  Passes input to output.  Traverse does
%> nothing.
%>
%> @version 1
%> @author Robert Borkowski
classdef sink < unit
    
    properties
        nInputs;
        nOutputs = 0;
    end
    
    methods
        
        %> @brief class constructor
        function obj = sink(nInputs)
            if nargin<1
                obj.nInputs = 1;
%             elseif nInputs < 1
%                 error('Number of inputs must be a positive integer.');
            else
                obj.nInputs = nInputs;
            end
        end
        
        %> @brief does nothing
        function traverse(~,~), end
        
        %> @brief pass input buffer contents to output buffer
        function varargout = readBuffer(obj)
            varargout = obj.inputBuffer;
            obj.inputBuffer = {};
        end
    
    end
end