%>@file ResampleSkewJitter_v1.m
%>@brief Resampler, rectangular anti-aliasing, and timing impairments insertion.
%>
%>@class ResampleSkewJitter_v1
%>@brief Resampler, rectangular anti-aliasing, and timing impairments insertion.
%>
%> This function resample the input signal doing anti-aliasing in a signal.
%> It also inserts timing impairments such as jitter, skew and clock deviance.
%>
%> __Observations__
%> The input signal shall be a complex signal_interface signal.
%>
%> __Example__
%> @code
%>   param.resamp.reamplingRate = 0.5;
%>   resamp = ResampleSkewJitter_v1(param.resamp);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = resample.traverse(sigIn);
%> @endcode
%>
%> __Advanced Example__
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
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
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
        %> - properties
        %>
        %> @param param.skew               Skew               - A vector with skews: [I1, Q1, I2, Q2, ...]. Normalized by symbol period.
        %> @param param.jitterVariance     JitterVariance     - The variance of a random walk Jitter.
        %> @param param.clockError         ClockError         - The clock deviance. E.g. 1e-6 means 1 ppm.
        %> @param param.outputSamplingRate OutputSamplingRate - The sampling rate of output signal. It will calculate automatically
        %>                                                      the resamplingRate if defined. It also has priority over resamplingRate.
        %> @param param.resamplingRate     ResamplingRate     - This is a downsampling rate. E.g. if the number of samples per symbol of input
        %>                                                      is 6 and the resampling rate is 3, the output will have 2 samples per symbol.
        %>                                                      If you need to do upsampling you need to define the inverse of upsampling rate.
        %>                                                      E.g. if the number of samples is 6 and the resampling rate is 0.5, the output will
        %>                                                      have 12 samples per symbol.
        %>
        %> @retval obj                 An instance of the class ResampleSkewJitter_v1
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
                if length(obj.skew) == 1 || length(obj.skew) ~= 2*size(input,2)
                    for ii = length(obj.skew):2*size(input,2)
                        obj.skew(ii) = obj.skew(length(obj.skew));
                    end
                end
                
                % Computing Jitter
                timing = cumsum([0 ; (in.Nss/obj.resamplingRate)*sqrt(obj.jitterVariance)*randn(floor(size(input,1)/obj.resamplingRate)-1,1)+(1+obj.clockError)*ones(floor(size(input,1)/obj.resamplingRate)-1,1)]);
                timing = repmat(timing, 1, 2*size(input,2));
                
                % Computing Timing
                for ii = 1:2*size(input,2)
                    timing(:,ii) = timing(:,ii) + in.Nss*obj.skew(ii)/obj.resamplingRate + 20/obj.resamplingRate;
                end
                
                output = zeros(floor(size(input,1)/obj.resamplingRate), size(input,2));
                
                for ii = size(input,2):-1:1
                    % Rectangular filtering and resampling
                    if max(max(timing)) < (length(input(:,ii))+38)/obj.resamplingRate % Testing for extrapolation
                        auxiliaryInput = [input(end-19:end,ii) ; input(:,ii) ; input(1:20,ii)];
                    else
                        auxiliaryInput = [input(end-19:end,ii) ; input(:,ii) ; input(1:20+max(max(timing))*obj.resamplingRate - (length(input(:,ii))+20),ii)];
                    end
                    if obj.resamplingRate > 1 % Downsampling
                        %realSignal = conv(real(auxiliaryInput), (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss*obj.resamplingRate)*202+1)).', 'same');
                        realSignal = fastconvrealDFT(real(auxiliaryInput), (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss*obj.resamplingRate)*202+1)).');
                        realSignal = realSignal(end-length(auxiliaryInput)+1:end).';
                        %imagSignal = conv(imag(auxiliaryInput), (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss*obj.resamplingRate)*202+1)).', 'same');
                        imagSignal = fastconvrealDFT(imag(auxiliaryInput), (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss*obj.resamplingRate)*202+1)).');
                        imagSignal = imagSignal(end-length(auxiliaryInput)+1:end).';
                        if ~mod(obj.resamplingRate,1)
                            display('Downsampling integer')
                            realSignal = downsample(realSignal, obj.resamplingRate);
                            imagSignal = downsample(imagSignal, obj.resamplingRate);
                        else
                            realSignal = interp1(1:length(auxiliaryInput), real(auxiliaryInput), 1:obj.resamplingRate:length(auxiliaryInput), 'spline').';
                            imagSignal = interp1(1:length(auxiliaryInput), imag(auxiliaryInput), 1:obj.resamplingRate:length(auxiliaryInput), 'spline').';
                        end
                    else % Upsampling
                        if ~mod(1/obj.resamplingRate,1)
                            realSignal = conv(upsample(real(auxiliaryInput), round(1/obj.resamplingRate)), (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss/obj.resamplingRate)*202+1)).', 'same');
                            imagSignal = conv(upsample(imag(auxiliaryInput), round(1/obj.resamplingRate)), (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss/obj.resamplingRate)*202+1)).', 'same');
                        else
                            realSignal = conv(interp1(1:length(auxiliaryInput), real(auxiliaryInput), 1:obj.resamplingRate:length(auxiliaryInput)).', (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss/obj.resamplingRate)*202+1)).', 'same');
                            imagSignal = conv(interp1(1:length(auxiliaryInput), imag(auxiliaryInput), 1:obj.resamplingRate:length(auxiliaryInput)).', (obj.resamplingRate)*sinc(in.Nss*linspace(-101, 101, (in.Nss/obj.resamplingRate)*202+1)).', 'same');
                        end
                    end
                    
                    % Skew, Jitter and Clock Error Insertion
                    output(:,ii) = interp1(1:size(realSignal,1), realSignal, timing(:,2*ii-1), 'spline');
                    %                     clear realSignal
                    output(:,ii) = output(:,ii) + 1j*interp1(1:size(imagSignal,1), imagSignal, timing(:,2*ii), 'spline');
                    clear imagSignal
                end
                
                out = in.set(output);
                out = out.set('Fs', out.Fs/obj.resamplingRate);
                
            end
        end
    end
end




