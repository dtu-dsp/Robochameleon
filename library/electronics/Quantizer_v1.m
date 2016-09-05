%>@file Quantizer_v1.m
%>@brief Quantizer is a unit that outputs a quantized version of input signal interface.
%>
%>@class Quantizer_v1
%>@brief Quantizer is a unit that outputs a quantized version of input signal interface.
%>
%>
%> This unit implements a quantizer.
%>
%> __Observations__
%>
%> It receives complex signals and outputs complex signals. If you have a
%> multimode (multicolumn) signal, it will quantize each column.
%>
%> __Example__
%> @code
%>   % Here we put a FULLY WORKING example using the MINIMUM set of required parameters
%>   quantizer = Quantizer_v1(param.quantizer);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 193.1e12;
%>   param.sig.Rs = 10e9;
%>   Ein = (-100000:100000);
%>   Ein = Ein(randperm(length(Ein))) + 1j*Ein(randperm(length(Ein)));
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = quantizer.traverse(sigIn);
%> @endcode
%>
%>
%> __Advanced Example__
%> @code
%>   % Here we put a FULLY WORKING example using a more extended set of parametersedit
%>   param.quantizer.targetENoB      = 4;
%>   param.quantizer.bitResolution   = 10;
%>   param.quantizer.location = 'Transmitter';
%>   quantizer = Quantizer_v1(param.quantizer);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 193.1e12;
%>   param.sig.Rs = 10e9;
%>   Ein = (-100000:100000);
%>   Ein = Ein(randperm(length(Ein))) + 1j*Ein(randperm(length(Ein)));
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = quantizer.traverse(sigIn);
%> @endcode
%>
%>
%>
%> __Output results structure__
%>
%> The following results are produced and stored in the structure _results_:
%> * __measuredENoB__ Actual effective number of bits achieved by Quantizer.
%>
%> __References__
%>
%> * \anchor BookAuthor1 [1] https://en.wikipedia.org/wiki/Quantization_(signal_processing)
%> * \anchor BookAuthor2 [2] https://en.wikipedia.org/wiki/Effective_number_of_bits
%>
%> @author Júlio Diniz
%> @version 1
classdef Quantizer_v1 < unit
    
    properties
        %> Number of Outputs
        nOutputs = 1;
        %> Number of Inputs
        nInputs = 1;
        %> Resolution of DAC in bits
        bitResolution = 8;
        %> Target Effective Number of Bits
        targetENoB;
        %> Quantizer location
        location = 'Transmitter';
    end
    
    methods
        %> @brief Class constructor
        %>
        %> @param param.bitResolution   BitResolution - is the resolution of your quantizer. [Default: 8]
        %> @param param.targetENoB      TargetENoB    - is the ENoB target that you want to achieve adding noise. (Optional)
        %>
        %> @retval obj      An instance of the class Quantizer_v1
        function obj = Quantizer_v1(param)
            obj.setparams(param, {}, {'location', 'targetENoB', 'bitResolution'})
        end
        
        function out = traverse(obj, in)
            
            
            %> Normalize input
            inputSignal = obj.normalizeInput(in.getRaw);
            
            %> Quantizing the signal
            outputSignal = quantization(obj, inputSignal);
                        
            %> Adding Noise
            outputSignal = addnoise(obj,inputSignal,outputSignal);
                        
            if strcmp(obj.location, 'Receiver')
                %> Normalize output
                outputSignal = outputSignal/(2^(obj.bitResolution-1));
                %> Requantizing
                outputSignal = quantization(obj, outputSignal);
            end
            
            %> Computing ENoB
            for ii = 1:size(outputSignal,2)
                noisePower(2*ii-1) = mean(real(2^(obj.bitResolution-1)*inputSignal(:,ii)-outputSignal(:,ii)).^2);
                noisePower(2*ii  ) = mean(imag(2^(obj.bitResolution-1)*inputSignal(:,ii)-outputSignal(:,ii)).^2);
                outputPower(2*ii-1) = mean(real(outputSignal(:,ii)).^2);
                outputPower(2*ii  ) = mean(imag(outputSignal(:,ii)).^2);
            end
            
            %> Results
            for ii = 1:length(outputPower)
                obj.results.measuredENoB(ii) = (10*log10((outputPower(ii))/noisePower(ii))-10*log10(3/2))/(20*log10(2));
            end
            
            %> Defining Output as a signal interface
            out = in.set(outputSignal);
            
        end
        
        function out = normalizeInput(obj,in)
            %> Searching maximum value of the signal
            samplepeak = max(max(abs([real(in) imag(in)])));
            %> Normalizing signal with maximum value
            out = in/samplepeak;
        end
        
        
        function out = quantization(obj, in)
            %> Quantizing the signal for values between 1 and 2^bitResolution
            out = round(((2^(obj.bitResolution-1)))*(in + (1+1j)*(1+1/(2^obj.bitResolution))));
            %> Fixing outliers
            out(real(out) > 2^obj.bitResolution) = 2^obj.bitResolution + 1j*imag(out(real(out) > 2^obj.bitResolution));
            out(imag(out) > 2^obj.bitResolution) = 1j*2^obj.bitResolution + real(out(imag(out) > 2^obj.bitResolution));
            out(real(out) < 1) = 1 + 1j*imag(out(real(out) < 1));
            out(imag(out) < 1) = 1j + real(out(imag(out) < 1));
            %> Recentering the signal
            out = out - (1+1j)*(2^obj.bitResolution+1)/2;
        end
        
        function out = addnoise(obj,in,out)
            if ~isempty(obj.targetENoB)
                if length(obj.targetENoB) ~= 2*size(out,2)
                    for ii = 1:2*size(out,2)
                        obj.targetENoB(ii) = obj.targetENoB(1);
                    end
                end
                for ii = 1:size(out,2)
                    distortionPower(2*ii-1) = mean(real(2^(obj.bitResolution-1)*in(:,ii)-out(:,ii)).^2);
                    distortionPower(2*ii  ) = mean(imag(2^(obj.bitResolution-1)*in(:,ii)-out(:,ii)).^2);
                    inputPower(2*ii-1) = mean(real(2^(obj.bitResolution-1)*in(:,ii)).^2);
                    inputPower(2*ii  ) = mean(imag(2^(obj.bitResolution-1)*in(:,ii)).^2);
                    noisePower(2*ii-1) = inputPower(2*ii-1)/(3*2^(2*obj.targetENoB(2*ii-1)-1)-1) - distortionPower(2*ii-1);
                    noisePower(2*ii  ) = inputPower(2*ii  )/(3*2^(2*obj.targetENoB(2*ii  )-1)-1) - distortionPower(2*ii  );
                    if sum(noisePower < 0)
                        robolog('ENoB cannot be achieved in mode %d, no noise added.', 'NFO0', ii);
                        noisePower(noisePower<0) = 0;
                    end
                    out(:,ii) = out(:,ii) + sqrt(noisePower(2*ii-1))*randn(size(out,1),1) + 1j*sqrt(noisePower(2*ii))*randn(size(out,1),1);
                end
            end
        end
        
    end
    
    
    
    
    
    
end
