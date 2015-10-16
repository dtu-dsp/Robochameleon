%> @file PulseShaper_v1.m
%> @brief Upsampling and pulse shaping
%>
%> @class PulseShaper_v1
%> @brief Upsampling and pulse shaping
%>
%> Performs both upsampling and pulse shapping. Accepted shapes:
%>
%> * Gaussian
%> * Raised Cosine
%>
%> @author Miguel Iglesias
classdef PulseShaper_v1 < unit
    
    properties
        %> Number of inputs
        nInputs=1;
        %> Number of outputs
        nOutputs=1;
        %> Upsampling factor
        US_factor;  
        %> Filter type {'Gaussian'| 'Cosine'}
        type;
        %> Normalized filter bandwidth with respect to symbol rate (relevant for Gaussian filtering)
        bandwidth;  
        %> Rolloff factor (relevant for Sqrt/Normal raised cosine)
        rolloff;  
        %> Filter length in symbols
        Nsym; 
        %> Frequency shift
        freqShift;  
        %> Phase shift
        phase;      
        
        %> Filter taps
        taps;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %>
        %> @param param.US_factor     Upsampling factor
        %> @param param.type          Filter type {'Gaussian'| 'Cosine'}
        %> @param param.bandwidth     Normalized filter bandwidth with respect to symbol rate (relevant for Gaussian filtering)
        %> @param param.rolloff   Rolloff factor (relevant for Sqrt/Normal raised cosine)
        %> @param param.Nsym   Filter length in symbols
        %> @param param.freqShift   Frequnecy shift. [Default: 0]
        %> @param param.phase   Phase shift. [Default: 0]
        %>
        %> @retval obj      An instance of the class PulseShaper_v1
        function obj = PulseShaper_v1(param)
            %Intialize parameters
            obj.US_factor = param.US_factor;
            obj.type = param.type;
            obj.bandwidth = paramdefault(param, 'bandwidth', NaN);
            obj.rolloff = paramdefault(param, 'rolloff', NaN);
            obj.Nsym = param.Nsym;
            obj.freqShift = paramdefault(param, 'freqShift', 0);
            obj.phase = paramdefault(param, 'phase', 0);

        end
        
        %> @brief Upsamples and shapes the signal
        function sig = traverse(obj,sig)
            % Create new signal with correct parameters
            sig = signal_interface(sig.get, struct('Rs', sig.Rs, 'Fs', obj.US_factor*sig.Fs, 'Fc', sig.Fc, 'P', sig.P));
            % Usample and design filter accordingly
            if strcmp(obj.type, 'Gaussian')
                sig = sig.fun1(@(x) rectpulse(x,obj.US_factor));
                h = fdesign.pulseshaping(sig.Nss, obj.type, 'Nsym,BT',obj.Nsym,obj.bandwidth, sig.Fs);
            elseif strfind(obj.type, 'Cosine')
                sig = sig.fun1(@(x) upsample(x,obj.US_factor));
                h = fdesign.pulseshaping(sig.Nss, obj.type, 'Nsym,Beta',obj.Nsym,obj.rolloff);                
            end
            Hd = design(h);
            % Upconvert and phase offset
            t_filt = linspace(0,obj.Nsym*sig.Nss/sig.Fs, length(Hd.Numerator));
            obj.taps = Hd.Numerator.*cos(2*pi*obj.freqShift*t_filt+obj.phase);
            % Perform filtering
            sig = sig.fun1(@(x) filter(obj.taps, 1, x));
            % Eliminate transients at the begining and end
%             fltDelay = obj.Nsym/(2*sig.Rs);   % Filter group delay in seconds
%             sig = sig.fun1(@(x) x(fltDelay*sig.Fs+1:end-fltDelay*sig.Fs));
        end
        
        %> @brief Returns filter taps
        function taps = getTaps(obj)
            taps = obj.taps(:);
        end

    end
end
