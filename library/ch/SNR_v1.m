%>@file SNR_v1.m
%>@brief SNR loading class definition file
%>
%>@class SNR_v1
%>@brief Signal-to-noise (SNR) loading block
%>
%> Adds noise based on desired SNR per bit and constellation order.
%>
%> All the input power is considered signal power.  If you need to set the SNR to a particular value, for now, 
%> use OSNR_v1 with appropriate parameters instead.  This block is meant for easy comparison to theory.
%>
%> Example:
%> @code
%> param = struct('SNR', 20, 'M', 4);
%> snr = SNR_v1(param);
%> 
%> param.sig.L = 10e6;
%> param.sig.Fs = 64e9;
%> param.sig.Fc = 193.1e12;
%> param.sig.Rs = 10e9;
%> param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%> E = rand(1000,2);
%>
%> sIn = signal_interface(E, param.sig);
%> sOut = snr.traverse(sIn);
%> sOut.P.getOSNR(sOut)
%> @endcode
%> This will generate a signal (in this example, of noise), then add more noise to it using snr.  The optical SNR (OSNR)
%> is then calculated using pwr::getOSNR.  This is not the most effective way to convert SNR to OSNR, just an example.
%>
%> @see OSNR_v1
%>
%> @author Miguel Iglesias Olmedo
%>
%> @version 1
classdef SNR_v1 < unit
    
    properties
	%> Number of inputs
        nInputs = 1;
	%> Number of outputs
        nOutputs = 1;
	%> Desired SNR (per bit) in dB
        SNR;
	%> Constellation order
        M;
    end
    
    methods
    %> @brief class constructor
        function obj = SNR_v1(param)
            obj.SNR = param.SNR;
            obj.M = param.M;
        end
	
	%> @brief Add noise
	%>
	%> This function was copied from an older version of the code
	%> @param x input signal
	%> @param Rs baud rate
	%> @param Fawg signal sampling rate
	%> @retval y noisy signal
        function y = addNoise(obj, x, Rs, Fawg)
            % Calculate energy per bit
            EbNo=10^(obj.SNR/10);
            Es = sum(abs(x).^2)/length(x)/Rs;
            Eb = Es/log2(obj.M);
            % Calculate one-sided power spectral density of the noise
            No = Eb/EbNo;
            % Calculate average power of noise
            pn = No*Fawg/2;
            % Generate noise
            if isreal(x)
                noise=sqrt(pn)*randn(1,length(x))';
            else
                noise=sqrt(pn)*(randn(1,length(x))+1i*randn(1,length(x)))';
            end
            % Add the noise
            y = x + noise;
        end
	    
        %> @brief main function
        function sig = traverse(obj, sig)
            %Check for reasonable input
            SNR_save = obj.SNR;
            if obj.SNR>sig.P.SNR
                robolog('SNR can only be decreased', 'ERR');
            elseif sig.P.SNR<inf
                robolog('Assume the input signal might be noisy (Use SNR information)');
                obj.SNR = 10*log10(sig.P.SNR('lin')*(10^(obj.SNR/10))/(sig.P.SNR('lin')-10^(obj.SNR/10)));
            end
            %Add noise
            sig = sig.fun1(@(x) obj.addNoise(x, sig.Rs, sig.Fs));            
            %track SNR & total power
            PCol_out = sig.PCol;
            for jj=1:sig.N
                Pn = sig.PCol(jj).Ptot-obj.SNR; %Pn in dBm
                PCol_out(jj) = pwr(SNR_save, {sig.PCol(jj).Ptot('W')+1e-3*10^(Pn/10), 'W'});
            end
            sig=set(sig, 'PCol', PCol_out);
        end
    end
    
end

