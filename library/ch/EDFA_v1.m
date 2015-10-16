%>@file EDFA_v1.m
%>@brief Implementation of a liner EDFA model
%>
%>@class EDFA_v1
%>@brief Linear EDFA model
%> 
%>  @ingroup physModels
%>
%> It amplify the input signal by multiplying the input field by the square root of the specified gain and
%> it adds to it an Amplified Spontaneous Emission (ASE) noise, which power density is determined by the specified
%> noise figure.
%>
%> The noise power is determined as Noise spectral density * Sampling frequency. For a complex baseband
%> signal the sampling frequency corresponds to the "simulation" bandwidth.
%>
%> __Example:__
%> @code
%>   param.edfa.gain  = 16;
%>   param.edfa.NF    = 5;
%>
%>   s1 = rand(1000,2);
%>   Ein = signal_interface(s1,struct('Fs',10e9,'Fc',193.1e12,'Rs',1e9,'PCol', [pwr(20,{-16,'dBm'}), pwr(25,{-18,'dBm'})]))
%>
%>   edfa = EDFA_v1(param.edfa);
%>
%>   Eout = edfa.traverse(Ein);
%> @endcode
%>
%> __References:__
%>
%> * [1] Agrawal, Gowind P.: Fiber-Optic Communication Systems. 3rd : John Wiley & Sons, 2002.
%> * [2] Essiambre, et al. (2010). Capacity Limits of Optical Fiber Networks.
%>
%> @author Molly Piels
%> @author Simone Gaiarin
%> @version 1
classdef EDFA_v1 < unit
    
    properties
        %> Number of input arguments
        nInputs = 1; 
        %> Number of output arguments
        nOutputs = 1; 
        %> EDFA gain [dB]
        gain;
        %> EDFA noise figure [dB]
        NF;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Constructs an object of type EDFA_v1.
        %>
        %> @param param.gain     Gain [dB].
        %> @param param.NF       Noise figure [dB].
        function obj = EDFA_v1(param)
            obj.setparams(param);
        end
        
        %> @brief Amplify the signal and add ASE noise
        %>
        %> @param in    The signal_interface of the signal to be amplified
        %> @retval out  The signal_interface of the amplified signal with extra ASE noise
        function out = traverse(obj, in)                       
            NFlin = 10^(obj.NF/10); % dB -> linear
            Glin = 10^(obj.gain/10); % dB -> linear
            
            % Spontaneous emission factor (population inversion factor)
            % line 1 incorrectly says that nsp<=1; actually nsp>=1)            
            % (Agrawal pp. 230-231), for ideal amplifier nsp=1
            nsp = (Glin*NFlin-1)/(2*(Glin-1)); 
            
            % Noise power = Noise spectral density * sampling frequency (Essiambre eq. 54 / Agrawal eq. 6.1.15)
            N0 = (Glin-1).*nsp*const.h*in.Fc;       % Noise density            
            Pn = max(0, N0*in.Fs);                  % Noise power per column (polarization). When power 
                                                    % is near zero, can be approximated to negative number,
                                                    % so let's round it to zero.
            
            noise = wgn(in.L, in.N, Pn, 'linear', 'complex');
            
            % Create the output power object
            PCol_ASE_noise = repmat(pwr(-inf, {Pn, 'W'}), 1, in.N);
            PCol_out = in.PCol*Glin + PCol_ASE_noise;
            
            % Get the output field
            Eout=sqrt(Glin)*get(in)+noise;            
            
            out=signal_interface(Eout,struct('Fs',in.Fs,'Rs',in.Rs, 'PCol', PCol_out, 'Fc', in.Fc));
        end
    end
end