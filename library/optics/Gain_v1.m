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
        
        function Eout = traverse(obj, sig)
            
            LinGain = 10^(obj.Gain/10); % Convert gain in dB to linear gain.   
            
            out = sig.fun1(@(x) sqrt(LinGain)*(x)); % Apply gain
            
            Signal = get(out).';            
            Psig = sum(abs(Signal(1,:)).^2 + abs(Signal(2,:)).^2)/length(Signal(1,:));
            Psig_dBm = 10*log10(Psig/1e-3);           
            
            % Output field:
            Eout = signal_interface(Signal.',struct('Fs',sig.Fs,'Fc',sig.Fc,'Rs',sig.Rs,'P',pwr(Inf,Psig_dBm)));
        end
    end
    
end

