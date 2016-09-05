classdef Gain_v1 < unit
    %>@file Gain_v1.m
    %>@brief Implements user defined arbitrary signal gain in power.
    % 
    %>@class Gain_v1
    %>@brief This class implements user defined arbitrary signal gain in power. 
    %
    % 
    %
    %>@author Edson Porto da Silva
    %>@version 1
    
    properties
        %> Gain value in dB.
        Gain;           
        %> Block outputs
        nOutputs = 1;
        %> Block inputs
        nInputs = 1;
    end
    
    methods
        %> @brief Class constructor
        function obj = Gain_v1(param)
            obj.Gain = paramdefault(param,'Gain',0);
        end
        
        function Eout = traverse(obj, Ein)
            
            LinGain = 10^(obj.Gain/10); % Convert gain in dB to linear gain.   
            Signal = sqrt(LinGain)*get(Ein);            
                
            % Output field:
            Eout = signal_interface(Signal, struct('Fs',Ein.Fs,'Fc',Ein.Fc,'Rs',Ein.Rs,'P', pwr(Ein.P.SNR, Ein.P.Ptot + obj.Gain)));
        end
    end
    
end

