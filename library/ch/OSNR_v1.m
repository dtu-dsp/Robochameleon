%>@file OSNR_v1.m
%>@brief OSNR loading class definition file
%>
%>@class OSNR_v1
%>@brief Optical signal-to-noise (OSNR) loading block
%>
%> Adds noise based on desired optical SNR (OSNR) and input signal power.
%>
%> If the input signal is noisy (SNR ~= inf), a quantity of noisy required to reach the desired OSNR 
%> will be added to the noise already present.
%> If assumeNoiseFreeEnabled is set to 1, the information on input noise are discarded and all the
%> input power will be considered signal power.
%>
%> Do not cascade many of these; Use EDFA instead (see EDFA_v1).
%>
%> Example:
%> @code
%> param = struct('OSNR', 20);
%> osnr = OSNR_v1(param);
%> 
%> param.sig.L = 10e6;
%> param.sig.Fs = 64e9;
%> param.sig.Fc = 193.1e12;
%> param.sig.Rs = 10e9;
%> param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%> E = rand(1000,2);
%>
%> sIn = signal_interface(E, param.sig);
%> sOut = osnr.traverse(sIn);
%> sOut.P.getOSNR(sOut)
%> @endcode
%>
%> @author Molly Piels
%> @author Simone Gaiarin
%>
%> @version 1
classdef OSNR_v1 < unit

    properties
        %> Optical signal-to-noise ratio (OSNR) [dB]
        OSNR;
        %> Noise bandwidth [nm]
        NBW = 0.1;
        %> Flag to assume the input signal is noise free (ignore SNR information)
        assumeNoiseFreeEnabled = 0;
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;
    end
    
    methods
        
        %>@brief Class constructor
        %>
        %> Construct an OSNR object that will add the amount of noise
        %> required to obtain the specified OSNR when traversed.
        %>
        %> @param param.OSNR Desired OSNR [dB].
        %> @param param.NBW Noise bandwidth [nm]. [Default: 0.1].
        %> @param param.assumeNoiseFreeEnabled Ignore input signal SNR information. [Default: false].
        %>
        %> @retval obj instance of the OSNR_v1 class
        function obj = OSNR_v1(param)
            obj.setparams(param);
        end
        
        %>@brief Traverse function
        %>
        %> Adds noise based on desired optical SNR (OSNR) and input signal power.
        %> Automatically tracks power and signal SNR.
        %>
        %> @param sig Noise free input signal 
        %>
        %> @retval sig Noise loaded signal
        function sig = traverse(obj, sig)
            
            lambda = const.c/sig.Fc;
            NBW_Hz = const.c/(lambda-.5*1e-9*obj.NBW)-const.c/(lambda+.5*1e-9*obj.NBW); % Noise bandwidth [Hz]
            
            if obj.assumeNoiseFreeEnabled
                % WARNING: Does this make sense?
                robolog('Assume the input signal is noise free (Ignore SNR information)');
                Ps = sig.P.Ptot('W');   % Assume all the power in the signal is signal power
                PnIn = 0;
                
                % Set SNR to inf to reflect the fact that power is all signal power.
                % Reuired for subsequent calculation.
                for i=1:length(sig.PCol)
                    PCol_new(i) = pwr(inf, {sig.PCol(i).P('W'), 'W'});
                end
                sig = sig.set('PCol', PCol_new);
            else
                robolog('Assume the input signal might be noisy (Use SNR information)');
                Ps = sig.P.Ps('W');     % Consider only the signal power specified in the power object
                                        % and add a quantity of noise to reach the desired OSNR
                PnIn = sig.P.Pn('W');   % Noise power at the input
                currentOSNR = pwr.getOSNR(sig);
                if obj.OSNR > currentOSNR
                    robolog('OSNR can only be decreased', 'ERR');
                end
            end
            OSNR_lin = 10^(obj.OSNR/10);
            N0 = (Ps/OSNR_lin)/NBW_Hz;          % Noise power density
            Pn = N0*sig.Fs - PnIn;              % Noise power (over the signal bandwidth)
            PnPerColumn = Pn / sig.N;           % The total noise power is split evenly among
                                                % the columns (polarizations) of the signal
            
            %Warn user if they seem to be using this oddly
            %New noise power, new SNR
            Pn_dBm_new = 10*log10(Pn);
            if Pn_dBm_new-sig.P.Pn<10
                robolog('New noise power within 10 dB of old noise power, SNR may be dominated by another part of the system', 'WRN');
            end
            
            % Generate the AWG noise and create a noise signal_interface with the same number of columns
            % as the input, so that we can add them. The power and SNR are automatically tracked in this way.
            sigNoiseParam = struct( ...
                            'Fs', sig.Fs, ...
                            'Fc', sig.Fc, ...
                            'Rs', sig.Rs, ...
                            'P', pwr(-inf, {Pn, 'W'}) ...
                            );
            nPoints = length(sig.getRaw);
            En = wgn(nPoints, sig.N, PnPerColumn, 'linear', 'complex');
            noise = signal_interface(En, sigNoiseParam);
            
            % Add noise to the signal
            sig = sig + noise;
        end
    end
end
