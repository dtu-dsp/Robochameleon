%>@file PD_v1.m
%>@brief photodiode class definition file
%>
%>@class PD_v1
%>@brief photodiode model
%> 
%>  @ingroup physModels
%>
%>This class models a photodiode with responsivity, noise, and bandwidth.
%>The new output power is the electrical power calculated assuming a 50
%>ohm environment.  The noise includes both shot and thermal noise.  The
%>bandwidth is modeled using a 2nd order butterworth filter.
%>
%>Example:
%>@code
%>param=struct('Responsivity', 1, 'Bandwidth', 20e9, 'Idark', 1e-9);
%>detector = PD_v1(param);
%>@endcode
%>
%>@author Miguel Iglesias
%>Modified 15/8/2014 Molly Piels - added noise
%>@version 1
classdef PD_v1 < unit
    
    properties
        nInputs=1;
        nOutputs=1;
        
        %>Responsivity in A/W
        Responsivity;      
        %>Bandwidth in Hz
        Bandwidth;         
        
        %>Noise equiv. thermal resistance (ohms) - default 50
        Rtherm;     
        %>Noise equiv. temperature (K) - default 290
        T;
        %>Dark current (A) - default 0
        Idark;
        
        
    end
    
    methods
        %>@brief Class constructor
        %>@retval obj instance of the PD_v1 class
        function obj = PD_v1(param)
            obj.Responsivity = param.Responsivity;
            obj.Bandwidth = param.Bandwidth;
            obj.Rtherm=paramdefault(param, 'Rtherm', 50);
            obj.Idark=paramdefault(param, 'Idark', 0);
            obj.T=paramdefault(param, 'T', 290);
        end
        
        %>@brief Traverse function
        %>
        %> Calculates appropriate shot noise (2qI) and thermal noise
        %> (4kT/R) currents, then applies square-law detection (current is
        %> proportional to (Ex^2+Ey^2), not (Ex+Ey)^2) and adds that noise
        %> current.  Finally, low-pass filters.
        %>
        %>@retval out photodiode output
        %>@retval results no results
        function out = traverse(obj, in)
            % Modify the power according to responsivity parameter
            P = 10*log10(in.P.Ps('W')*obj.Responsivity);       %in dBW
            
            %noise
            Pnum=sum(pwr.meanpwr(get(in)));               %numerically calculated power
            CF=Pnum/(10^(P/10));                      %correction factor (assume field expressed in normalized units)
            Pnshot = 2*const.q*(obj.Responsivity*(10^(P/10))+obj.Idark)*in.Fs;
            Pntherm = 4*const.kB*obj.T/obj.Rtherm*in.Fs;
            noise=wgn(in.L, 1, Pnshot*CF, 'linear', 'real')+wgn(in.L, 1, Pntherm*CF, 'linear', 'real');
            
            SNR = 10*log10(in.P.Ps('W')/(in.P.Pn('W')+Pnshot+Pntherm));
            newPower = pwr(SNR, {P, 'dBW'});
          
            Fnew=sum(get(in).*conj(get(in)), 2)+noise;      %photocurrents from each polarization add incoherently
            out=signal_interface(Fnew, struct('Fs',in.Fs,'Rs',in.Rs, 'P', newPower, 'Fc', 0));
            %low-pass filter
            [b,a] = butter(2,2*obj.Bandwidth/in.Fs, 'low');
            out=fun1(out, @(x)filter(b,a,x));
        end
        
    end
    
end

