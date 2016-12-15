%>@file ResampleSkewJitter_v1.m
%>@brief Resampler, rectangular anti-aliasing, and timing impairments insertion.
%>
%>@class ResampleSkewJitter_v1
%>@brief Resampler, rectangular anti-aliasing, and timing impairments insertion.
%>
%> @ingroup coreDSP
%>
%> This function resample the input signal doing anti-aliasing in a signal.
%> It also inserts timing impairments such as jitter, skew and clock deviance.
%>
%> __Observations__
%> The input signal shall be a complex signal_interface signal.
%>
%> __Example__
%> This example upsamples the input signal to a sampling rate of 2X.
%> @code
%>   param.resamp.resamplingRate = 0.5;
%>   resamp = ResampleSkewJitter_v1(param.resamp);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = resample.traverse(sigIn);
%> @endcode
%>
%> __Advanced Example__
%> This example defines an output sampling rate, and also adds skew, jitter and clock deviance.
%> @code
%>   param.resamp.outputSamplingRate = 128e9;
%>   param.resamp.skew = [0 0.5];
%>   param.resamp.jitterVariance = 1e-8;
%>   param.resamp.clockError = 5e-6;
%>   upsamp = ResampleSkewJitter_v1(param.resamp);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = resample.traverse(sigIn);
%> @endcode
%>
%> @author jcesardiniz
%> @version 1
classdef ResampleSkewJitter_v1 < unit
    
    properties
        %> Number of outputs
        nOutputs = 1;
        %> Number of inputs
        nInputs = 1;
        %> Downsampling Rate
        resamplingRate = 1;
        %> Output Sampling Rate
        outputSamplingRate
        %> Skew
        skew = 0;
        %> Jitter Variance
        jitterVariance = 0;
        %> Clock deviation
        clockError = 0;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> @param param.skew               A vector with skews: [I1, Q1, I2, Q2, ...]. Normalized by symbol
        %>                                 period.
        %>
        %> @param param.jitterVariance     The variance of a random walk Jitter.
        %>
        %> @param param.clockError         The clock deviance. E.g. 1e-6 means 1 ppm.
        %>
        %> @param param.outputSamplingRate The sampling rate of output signal. It will calculate automatically
        %>                                 the resamplingRate if defined. It also has priority over
        %>                                 resamplingRate.
        %>
        %> @param param.resamplingRate     This works as a downsampling rate. E.g. if the number of samples per
        %>                                 symbol of input is 6 and "resamplingRate" is 3, the output will be
        %>                                 2 samples per symbol. If you need to do upsampling instead you need
        %>                                 to define the inverse of upsampling rate. E.g. if the number of
        %>                                 samples is 6 and the "resamplingRate" is 0.5, the output will be
        %>                                 12 samples per symbol.
        %>
        %> @retval obj     An instance of the class ResampleSkewJitter_v1
        function obj = ResampleSkewJitter_v1(param)
            obj.setparams(param,{},{'skew', 'jitterVariance','clockError','resamplingRate','outputSamplingRate'})
            if ~isempty(obj.outputSamplingRate)
                obj.resamplingRate = [];
            end
        end
        
        function out = traverse(obj, in)
            if ~isempty(obj.outputSamplingRate)
                obj.resamplingRate = in.Fs/obj.outputSamplingRate;
            end
            
            % special case for doing nothing
            if obj.resamplingRate == 1 && all(obj.skew==0) && obj.jitterVariance == 0 && obj.clockError == 0
                out = in;
                return
            else
                
                input = in.get;
                
                % Computing Skew
                if length(obj.skew) == 1
                    obj.skew = ones(1,2*size(input,2))*obj.skew;
                elseif length(obj.skew) ~= 2*size(input,2)
                    obj.skew(2*size(input,2)) = 0;
                end
                
                % Computing Jitter
                timing = cumsum([0 ; (in.Nss/obj.resamplingRate)*sqrt(obj.jitterVariance)* ...
                    randn(floor(size(input,1)/obj.resamplingRate)-1,1)+(1+obj.clockError)* ...
                    ones(floor(size(input,1)/obj.resamplingRate)-1,1)]);
                timing = repmat(timing, 1, 2*size(input,2));
                
                % Computing Timing
                for ii = 1:2*size(input,2)
                    timing(:,ii) = timing(:,ii) + in.Nss*obj.skew(ii)/obj.resamplingRate + 20/obj.resamplingRate;
                end
                
                output = zeros(floor(size(input,1)/obj.resamplingRate), size(input,2));
                
                for ii = size(input,2):-1:1
                    % Rectangular filtering and resampling
                    if max(max(timing)) < (length(input(:,ii))+38)/obj.resamplingRate % Testing for extrapolation
                        signal = [input(end-19:end,ii) ; input(:,ii) ; input(1:20,ii)];
                    else
                        signal = [input(end-19:end,ii) ; input(:,ii) ; input(1:20+max(max(timing))* ...
                            obj.resamplingRate - (length(input(:,ii))+20),ii)];
                    end
                    if obj.resamplingRate > 1 % Downsampling
                        % Anti-aliasing filtering
                        signal = obj.antiAliasingFilter(signal, in.Nss, 'downsampling');
                        if ~mod(obj.resamplingRate,1) % Integer downsampling rate
                            signal = downsample(signal, obj.resamplingRate);
                        else % fractional downsampling rate
                            signal = interp1(1:length(signal), signal, 1:obj.resamplingRate:length(signal), ...
                                'spline').'; % Reinterpolating
                        end
                    else % Upsampling
                        if ~mod(1/obj.resamplingRate,1) % integer upsampling rate
                            signal = upsample((signal), round(1/obj.resamplingRate)); % Upsampling with zeros
                        else % fractional upsampling rate
                            signal = interp1(1:length(signal), (signal), 1:obj.resamplingRate:length(signal), ...
                                'spline').'; % Reinterpolating
                        end
                        % Anti-aliasing filtering
                        signal = obj.antiAliasingFilter(signal, in.Nss, 'upsampling');
                    end
                    
                    % Skew, Jitter and Clock Error Insertion
                    output(:,ii) = interp1(1:size(real(signal),1), real(signal), timing(:,2*ii-1), 'spline') + ...
                        + 1j*interp1(1:size(imag(signal),1), imag(signal), timing(:,2*ii), 'spline');
                end
                
                out = in.set(output);
                out = out.set('Fs', out.Fs/obj.resamplingRate);
                
            end
        end
        
        function out = antiAliasingFilter(obj, in, Nss, type)
            if strcmp(type, 'upsampling')
                % AAF means 'A'nti 'A'liasing 'F'ilter
                AAF = (obj.resamplingRate)*sinc(Nss*linspace(-101, 101, (Nss/obj.resamplingRate)*202+1)).';
            elseif strcmp(type, 'downsampling')
                AAF = (obj.resamplingRate)*sinc(Nss*linspace(-101, 101, (Nss*obj.resamplingRate)*202+1)).';
            end
            shiftLength = floor(length(AAF)/2);  % Computing number of samples for circshift()
            AAF(length(in)) = 0; % Filling up the filter with zeros
            AAF = circshift(AAF, [-shiftLength-1, 0]); % Shifting circularly the time-domaing filter to avoid lag
            out = ifft(fft(AAF).*fft(in)); % Applying the filter in frequency domain
        end
    end
end

