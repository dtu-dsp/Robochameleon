%> @file QuadratureImbalanceCompensation_v1.m
%> @brief I-Q imbalance correction
%>
%> @class QuadratureImbalanceCompensation_v1
%> @brief I-Q imbalance correction
%> 
%> @ingroup coreDSP
%>
%> Quadrature imbalance correction.  Seems
%> to be based on Gram-Schmidt.
%> 
%> @author Molly
%> @version 1
classdef QuadratureImbalanceCompensation_v1 < unit
    
    properties
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs  = 1;
        
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Takes no arguments
        function obj = QuadratureImbalanceCompensation_v1
        end
        
        %> @brief Main function
        function out = traverse(obj,in)
            
            obj.results.rho = nan(in.N,1);
            out=fun1(in, @(x) obj.quadimb(x));
            
            out = signal_interface(getRaw(out), struct('Rs', in.Rs, 'Fs', in.Fs, 'Fc', in.Fc, 'P', in.P));
                        
        end
        
        %> @brief IQ imbalance compensation routine
        %> 
        %> @param Ein complex baseband signal to be corrected 
        %> @retval Eout corrected and normalized signal
        function Eout=quadimb(obj, Ein)
            I = real(Ein);
            Q = imag(Ein);
            
            rho = mean(I.*Q);
            P_I =pwr.meanpwr(I);
            Q = Q - rho*I/P_I;
            P_Q = pwr.meanpwr(Q);
            
            Eout = pwr.normpwr(I/sqrt(P_I) + 1j*Q/sqrt(P_Q));
            
            %save imbalance
            idx = find(isnan(obj.results.rho), 1);
            obj.results.rho(idx) = rho;
        end
       
        
    end
    
end