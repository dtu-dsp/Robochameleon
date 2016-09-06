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
%>
%> __Notes__
%>
%> 1. Has a property for maximum input power, but signal clipping is not
%> implemented.
%> 
%> 2. Can be forced to emulate an array of balanced photodiodes for a dual-
%> or multi-mode coherent receiver by setting modeAdditionEnabled to false.
%> When this flag is true, all columns of a multimode signal will be summed
%> incoherently, as in a real photodiode.  When it's false, they are kept
%> independent and the output will have as many columns as the input.
%>
%> @author Molly Piels
%> @version 1
classdef BalancedPair_v1 < unit
    
    properties
        %> Responsivity (A/W)
        R = 1;
        %> Common-mode rejection ratio (dB)
        CMRR = inf; 
        %> 3dB cutoff frequency (Hz)
        f3dB = 40e9;  
        %> thermal resistance (ohm)
        Rtherm = 50; 
        %> maximum input power (NOT USED)
        Pmax;   
        
        %> Temperature (K)
        T = 290;    
        
        %> Flag to enable/disable incoherent addition of signals in different optical modes
        modeAdditionEnabled = true;
        
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
        %>  BPDparam.R = 1;
        %>  BPDparam.CMRR = 50;
        %>  BPDparam.f3dB = 28e9;
        %>  BPDparam.Rtherm = 50;
        %>  BPD = BalancedPair_v1(BPDparam);
        %>  @endcode
        %>
        %> @param param.R Responsivity [A/W] [Default: 1]
        %> @param param.f3dB electrical 3dB bandwidth [Hz] [Default: 40G]
        %> @param param.Rtherm resistance for thermal noise calculation [ohm] [Default: 50]
        %> @param param.CMRR common-mode rejection ratio [dB][Default: inf]
        %> @param param.T Temperature [K][Default: 290]
        %> @param param.modeAdditionEnabled [flag] [Default: true]
        %>
        %> @retval BalancedPair object
        function obj = BalancedPair_v1(param)
            obj.setparams(param);            
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
            
            %Truncate if necessary
            if in1.L>in2.L
                in1 = fun1(in1, @(x)x(1:in2.L));
            elseif in2.L>in1.L
                in2 = fun1(in2, @(x)x(1:in1.L));
            end
            
            % All following operations are performed on 'normalized
            % photocurrent': abs(whatever is in the signal's waveform)^2
            
            % save for later - inputs get overwritten
            Ps_an = in1.P.Ps('W')+in2.P.Ps('W');
            Pn_an =in1.P.Pn('W')+in2.P.Pn('W');
            Pin_an = Ps_an+Pn_an;
            
            % square-law detection and polarization addition
            in1f = getScaled(in1);
            in2f = getScaled(in2);
            in1f = in1f.*conj(in1f);
            in2f = in2f.*conj(in2f);
            if obj.modeAdditionEnabled
                in1f=sum(in1f, 2);
                in2f=sum(in2f, 2);
                nOutputSignals = 1;
                obj.checkDimensions(in1.N, in2.N);
            else
                nOutputSignals = in1.N;
                obj.checkDimensions(nOutputSignals, in2.N);
            end
            

            % subtraction with finite CMRR
            % also, responsivity
            R_mix=0.5./(10.^(obj.CMRR/10));
            %outmix = obj.R*(in1f*(R_mix+1)+in2f*(R_mix-1));
            outmix = bsxfun(@times, in1f, R_mix.' + 1) + bsxfun(@times, in2f, R_mix.' - 1);
            outmix = bsxfun(@times, outmix, obj.R.');
            %track output power and SNR
            Ps_out = pwr.meanpwr(outmix)/(1+Pn_an/Ps_an);
            Pn_out1 = Ps_out*Pn_an/Ps_an;
            
            %Add noise currents
            Pnshot = 2*const.q*obj.R.'*Pin_an*obj.f3dB;
            Pntherm = 4*const.kB*obj.T/obj.Rtherm*obj.f3dB;
            Pn_out = Pn_out1+Pnshot+Pntherm;
            noise_sig=wgn(length(outmix), nOutputSignals, Pnshot(1), 'linear', 'real')+wgn(length(outmix), nOutputSignals, Pntherm, 'linear', 'real');
            if length(Pnshot)>1
                for jj = 2:nOutputSignals
                    noise_sig(:,jj)=wgn(length(outmix), 1, Pnshot(jj), 'linear', 'real')+wgn(length(outmix), 1, Pntherm, 'linear', 'real');
                end
            end
            outn = outmix + noise_sig;
            
            PCol_out = pwr(inf, 0);
            for jj = 1:nOutputSignals
                PCol_out(jj) = pwr(10*log10(Ps_out(jj)/Pn_out(jj)), {Ps_out(jj),'W'});
            end
            
            out = in1.set('E', outn, 'PCol', PCol_out, 'Fc', 0);
            %out = signal_interface(outn, struct('Fs',in1.Fs,'Rs',in1.Rs, 'P', ...
            %    pwr(10*log10(Ps_out./Pn_out),{Ps_out,'W'}), 'Fc', in1.Fc-in2.Fc ));
            
            % low-pass filtering
            [b_lp,a_lp] = butter(2, 2*obj.f3dB/(in1.Fs));
            out = fun1(out, @(x)filter(b_lp,a_lp,x));
            out = out.fun1(@(x)x(min([16, out.L]):end));       %filter messes up first few samples
            
            % save mixing ratio
            obj.results = struct('Rmix', R_mix);
            
        end
        %> @brief Make sure number of specified properties is reasonable
        function checkDimensions(obj, N1, N2)
            if N1 ~= N2
                robolog('Number of input modes must be equal for both signals', 'ERR')
            end
            if ~isscalar(obj.R)
                if (length(obj.R) ~= N1)
                    robolog('Number of specified responsivities must be 1 or match input signal', 'ERR')
                end
                obj.R = obj.R(:);
            end
            if ~isscalar(obj.CMRR)
                if (length(obj.CMRR) ~= N1)
                    robolog('Number of specified CMRRs must be 1 or match input signal', 'ERR')
                end
                obj.CMRR = obj.CMRR(:);
            end
            if ~isscalar(obj.f3dB)
                robolog('Number of specified 3dB bandwidths must be 1', 'WRN')
                obj.f3dB = obj.f3dB(1);
            end
            if ~isscalar(obj.Rtherm)
                robolog('Number of specified 3dB bandwidths must be 1', 'WRN')
                obj.Rtherm = obj.Rtherm(1);
            end
            if ~isscalar(obj.T)
                robolog('Number of specified 3dB bandwidths must be 1', 'WRN')
                obj.T = obj.T(1);
            end
        end
        
    end
    
end