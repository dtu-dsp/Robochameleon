%> @file  sink.m
%> @brief stores the input signal.
%>
%> @class  sink
%> @brief stores the input signal.
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
        
        keep = 0;
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
        function [varargout] = readBuffer(obj)
            varargout = obj.inputBuffer;
            if(~ispref('robochameleon','debugMode') && ~getpref('robochameleon','debugMode'))
                if(~obj.keep)
                    obj.inputBuffer = {};
                end
            end
        end
        
        %> @brief set keepOutput flag
        function setKeep(obj, keep)
            obj.keep = keep;
        end
    
    end
end