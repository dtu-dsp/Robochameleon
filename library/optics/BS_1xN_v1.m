%> @file BS_1xN_v1.m
%> @brief Implementation of a non-polarizing beam splitter
%>
%> @class BS_1xN_v1
%> @brief Non-polarizing beam splitter
%>
%> @ingroup physModels
%> 
%> This block takes a single input and splits it into an arbitrary number 
%> of outputs (N). Multimode is supported. 
%> Power will be equally split among the outputs.
%>
%> __Example:__
%> @code
%>   param.bs.nOutputs = 3;
%>   bs = BS_1xN_v1(param.bs);
%>
%>   sigIn = createDummySignal();
%>   [sig1, sig2, sig3] = bs.traverse(sigIn);
%>   pabs(sigIn, sig1, sig2, sig3);
%> @endcode
%>
%> @see Polarizer_v1
%> @see PBC_Nx1_v1
%> @see BS_1xN_v1
%> @see run_TestBSandBC_v1
%>
%> @author Molly Piels 
%> @author Simone Gaiarin
classdef BS_1xN_v1 < unit
    
    properties
        nInputs = 1;    % Number of input arguments
        nOutputs;       % Number of output arguments
    end
    
    methods
        
        %> @brief Constructor
        %>
        %> @param param.nOutputs Number of outputs
        function obj = BS_1xN_v1(param)
            %Intialize parameters
            REQUIRED_PARAM = {'nOutputs'};
            obj.setparams(param, REQUIRED_PARAM);            
        end
        
        %> @brief Split the input signal in multiple outputs by rescaling the power
        %>
        %> @param in Input signal
        function varargout = traverse(obj, in)
            splitter = BranchSignal_v1(obj.nOutputs);            
            outs = cell(1, obj.nOutputs);
            [outs{:}] = splitter.traverse(in);
            for i=1:obj.nOutputs
                outs{i} = outs{i}*(1/sqrt(obj.nOutputs));
            end
            varargout = outs;
        end
    end
end
