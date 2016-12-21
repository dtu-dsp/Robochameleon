%> @file BalancedPair_v1.m
%> @brief Balanced pair model
%> 
%> @class BalancedPair_v1
%> @brief Balanced photodiode pair model
%> 
%>  @ingroup physModels
%>
%> Balanced pair model.  Includes responsivity, finite common-mode
%> rejection ratio, 3dB bandwidth, thermal, and shot noise contributions.
%> Has a property for maximum input power, but signal clipping is not
%> implemented.
%>
%> @author Molly Piels
%> @version 1
classdef BalancedPair_v2 < unit
    
    properties
        %> Responsivity (A/W)
        R;
        %> Common-mode rejection ratio (dB)
        CMRR; 
        %> 3dB cutoff frequency (Hz)
        f3dB;  
        %> thermal resistance (ohm)
        Rtherm; 
        %> maximum input power (NOT USED)
        Pmax;   
        
        %> Temperature (K)
        T = 290;                
        
        %> Number of input arguments
        nInputs = 2;  
        %> Number of output arguments
        nOutputs = 1; 
    end
    
    methods
        
        
        %>  @brief Class constructor
        %>
        %>  Class constructor
        %>
        %>  Example:
        %>  @code
        %>  BPD = BalancedPair_v1(struct('R', 1, 'CMRR', 50, 'f3dB', 28e9, 'Rtherm', 50));
        %>  @endcode
        %>
        %> @param param.R Responsivity (A/W)
        %> @param param.f3dB electrical 3dB bandwidth (Hz)
        %> @param param.Rtherm resistance for thermal noise calculation (ohm)
        %> @param param.CMRR common-mode rejection ratio (dB) (default infinite)
        %>
        %> @retval BalancedPair object
        function obj = BalancedPair_v2(param)
            % Intialize parameters
            obj.R = param.R;
            obj.f3dB = param.f3dB;
            obj.Rtherm = param.Rtherm;
            if isfield(param, 'CMRR')
                obj.CMRR = param.CMRR;            
            else
                obj.CMRR = inf;
            end
            if isfield(param, 'Pmax')
                obj.Pmax = param.Pmax;
            else
                obj.Pmax = inf;
            end
            
        end
        
        
        %>  @brief Traverse function
        %>
        %>  Performs square-law detection on both input signals, then
        %>  subtracts with finite CMRR, then adds noise, then low-pass
        %>  filters.
        %>  
        %> @param in1 input signal 1
        %> @param in2 input signal 2
        %>
        %> @retval out BPD output
        %> @retval results.Rmix mixing ratio from CMRR calculation
        function out = traverse(obj,in1, in2)
            
            % All following operations are performed on 'normalized
            % photocurrent': abs(whatever is in the signal's waveform)^2
            
            % save for later - inputs get overwritten
            Ps_an = in1.P.Ps('W')+in2.P.Ps('W');
            Pn_an =in1.P.Pn('W')+in2.P.Pn('W');
            Pin_an = Ps_an+Pn_an;  
            
            % square-law detection and polarization addition
            in1f = getRaw(in1);
            in2f = getRaw(in2);
%             in1f = getScaled(in1);
%             in2f = getScaled(in2);
            in1f = in1f.*conj(in1f);
            in2f = in2f.*conj(in2f);
            in1f = real(in1f);      
            in2f = real(in2f);      

            % subtraction with finite CMRR
            % also, responsivity
            R_mix=0.5/(10^(obj.CMRR/10));
            outmix = obj.R*(in1f*(R_mix+1)+in2f*(R_mix-1));
            %track output power and SNR
            Ps_out = pwr.meanpwr(outmix)/(1+Pn_an/Ps_an);
            Pn_out1 = Ps_out*Pn_an/Ps_an;
            
            %Add noise currents
            Pnshot = 2*const.q*obj.R*Pin_an*obj.f3dB;
            Pntherm = 4*const.kB*obj.T/obj.Rtherm*obj.f3dB;
            Pn_out = Pn_out1+Pnshot+Pntherm;
            noise_sig=wgn(length(outmix), 1, Pnshot, 'linear', 'real')+wgn(length(outmix), 1, Pntherm, 'linear', 'real');
            outn = outmix + noise_sig;
%             outn = outmix;
            
            % low-pass filtering
            [b_lp,a_lp] = butter(6, 2*obj.f3dB/(in1.Fs));
            outf = filter(b_lp,a_lp,outn);
%             outf = outn;
            
            out = signal_interface(outf, struct('Fs',in1.Fs,'Rs',in1.Rs, 'P', ...
                pwr(10*log10(Ps_out/Pn_out),{Ps_out,'W'}), 'Fc', in1.Fc-in2.Fc ));
            
            % save mixing ratio
            obj.results = struct('Rmix', R_mix);
            
        end
        
    end
    
end