%> @file OpticalHybrid_v1.m
%> @brief Passive part of an optical hybrid
%>
%> @class OpticalHybrid_v1
%> @brief Passive part of an optical hybrid
%> 
%> @ingroup physModels
%>
%> Simple 2x4 MMI model.
%>
%> __Example__
%> @code
%> hybrid = OpticalHybrid_v1(struct('phase_angle', pi/2));
%> @endcode
%>
%> Signal inputs: 2
%>      -For conventional I-Q definitions, signal goes to input 1, LO to input 2
%> 
%> Signal outputs: 4
%>       -Outputs 1 and 2 are in-phase (I+ and I-, respectively)
%>       -Outputs 3 and 4 are quadrature (Q+ and Q-, respectively)
%>
%> @author Molly Piels
%> @version 1
classdef OpticalHybrid_v1 < unit

    
    properties
        
        %> Optical hybrid phase angle [rad]
        phase_angle = pi/2; 
        
        %> Number of input arguments
        nInputs = 2; 
        %> Number of output arguments
        nOutputs = 4; 
    end
    
    methods
        
        %>  @brief Class constructor
        %>
        %>  Class constructor
        %>
        %> @param param.phase_angle Hybrid phase angle [rad] [Default: pi/2]
        function obj = OpticalHybrid_v1(params)
            if nargin<1, params = struct([]); end; obj.setparams(params);
        end
        
        %>  @brief Traverse function
        %>
        %>  Applies frequency shift to LO, then mixes LO with signal
        %> coherently
        %>
        %> @param sig Input signal
        %> @param lo Input local oscillator (swapping LO and signal swaps I and Q)
        %>
        %> @retval out1 I+
        %> @retval out2 I-
        %> @retval out3 Q+
        %> @retval out4 Q-
        %> @retval results no results
        function [out1,out2,out3,out4] = traverse(obj,sig,lo)
            if isscalar(obj.phase_angle);
                phase = exp(1j*obj.phase_angle);
            elseif length(obj.phase_angle == sig.N)
                phase = diag(exp(1i*obj.phase_angle));
            else
                robolog('Number of phase angles must be 1 or number of input modes (N)', 'ERR');
            end
                        
            out1 = (sig + lo)*(1/4);
            out2 = (sig + lo*-1)*(1/4);
            out3 = (sig + lo*phase)*(1/4);
            out4 = (sig + lo*phase*-1)*(1/4);
  
        end
        
    end
    
end