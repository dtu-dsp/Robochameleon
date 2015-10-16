%> @file  BranchSignal_v1.m
%> @brief Branches the input signal.
%>
%> @class  BranchSignal_v1
%> @brief Branches the input signal.
%>
%> Sends an exact copy of the input to each output.
%>
%> @version 1
classdef BranchSignal_v1 < unit
    
    properties
        %> Number of input arguments
        nInputs = 1; 
        %> Number of output arguments
        nOutputs; 
    end

    methods
        %> @brief Class constructor
        %>
        %> @param nOutputs number of outputs (default 2)
        %> @return instance of the BranchSignal_v1 class
        function obj = BranchSignal_v1(nOutputs)
            if nargin<1
                obj.nOutputs = 2;
            else
                obj.nOutputs = nOutputs;
            end
        end
        
        %> @brief Traverse function
        %>
        %> @param in input
        %> @return varargout array of copies of input
        function varargout = traverse(obj,in)
            varargout = repmat({in},1,obj.nOutputs);
        end
    end

end