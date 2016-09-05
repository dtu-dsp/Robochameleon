%> @file BC_Nx1_v1.m
%> @brief Implementation of a non-polarizing beam combiner
%>
%> @class BC_Nx1_v1
%> @brief Non-polarizing  Beam combiner
%>
%> @ingroup physModels
%> 
%> This block takes a multiple inputs and combine them in a single
%> output. Multimode is supported. 
%> Power will be summed.
%>
%> __Example:__
%> @code
%>   param.bc.nInputs = 3;
%>   bc = BC_Nx1_v1(param.bc);
%>
%>   sigIn1 = createDummySignal();
%>   sigIn2 = createDummySignal();
%>   sigOut = bc.traverse(sigIn1, sigIn2);
%>   pabs(sigIn1, sigIn2, sigOut);
%> @endcode
%>
%> @see Polarizer_v1
%> @see PBC_Nx1_v1
%> @see BS_1xN_v1
%> @see run_TestBSandBC_v1
%>
%> @author Molly Piels 
%> @author Simone Gaiarin
classdef BC_Nx1_v1 < unit
    
    properties
        nInputs;       % Number of input arguments
        nOutputs = 1;  % Number of output arguments
    end
    
    methods
        
        %> @brief Constructor
        %>
        %> @param param.Inputs Number of inputs
        function obj = BC_Nx1_v1(param)
            %Intialize parameters
            REQUIRED_PARAM = {'nInputs'};
            obj.setparams(param, REQUIRED_PARAM);
        end
        
        %> @brief Combine multiple input signals into a single output rescaling the power
        %>
        %> @param varargin Input signals
        %> @retval sum Combined signal
        function sum = traverse(obj, varargin)
            sum = varargin{1};
            for i=2:obj.nInputs
                sum = sum + varargin{i};
            end
        end
    end
end
