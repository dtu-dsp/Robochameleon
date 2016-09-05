%> @file DigitalPreFilter_v1.m
%> @brief A prefilter for digital signals.
%>
%> @class DigitalPreFilter_v1
%> @brief A prefilter for digital signals.
%>
%> This function implements a prefilter in order to mitigate filtering and
%> group delay impairments of the electrical front-end of DAC.
%>
%> __Observations__
%>
%> 1. This unit implements low-pass filtering mitigation by inverse
%> response of Gaussian low-pass filters.
%> 2. This unit implements group delay mitigation by inverse phase
%> response of Bessel filters.
%> 3. This unit alse receives user defined filters in time domain. 
%>
%>
%> __Example__
%> @code
%>   param.prefilter.gaussianOrder = 1;
%>   param.prefilter.gaussianBandwidth = 16e9;
%>   prefilt = DigitalPreFilter_v1(param.prefilter);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = prefilt.traverse(sigIn);
%> @endcode
%>
%>
%> __Advanced Example__
%> @code
%>   param.prefilter.gaussianOrder = 1;
%>   param.prefilter.gaussianBandwidth = 16e9;
%>   param.prefilter.besselOrder = 2;
%>   param.prefilter.besselBandwidth = 84e9;
%>   param.prefilter.userDefinedFilter = [1 0 1 ; 1 0 0]';
%>   prefilt = DigitalPreFilter_v1(param.prefilter);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = upsample((randi(2,1000,1)-1.5)*2 + 1j*(randi(2,1000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = prefilt.traverse(sigIn);
%> @endcode
%>
%> @author jcesardiniz
%>
%> @version 1
classdef DigitalPreFilter_v1 < unit
    
    properties
        %> Number of outputs
        nOutputs = 1;
        %> Number of inputs
        nInputs = 1;
        %> Order of Gaussian Pre-Filter
        gaussianOrder = 0;
        %> Bandwidth of Gaussian Pre-Filter
        gaussianBandwidth;
        %> Order of Bessel Pre-Filter
        besselOrder = 0;
        %> Bandwidth of Bessel Pre-Filter
        besselBandwidth;
        %> User defined filter in time domain, same sampling rate
        userDefinedFilter;
    end
    
    methods
        %>@brief Class constructor
        function obj = DigitalPreFilter_v1(param)
            obj.setparams(param,{},{'bypass','gaussianOrder','gaussianBandwidth','besselOrder','besselBandwidth', 'userDefinedFilter'})
        end
        
        function out = traverse(obj, in)
            
            while length(obj.gaussianOrder) < 2*in.N
                obj.gaussianOrder(end+1) = obj.gaussianOrder(end);
            end
            
            while length(obj.gaussianBandwidth) < 2*in.N
                obj.gaussianBandwidth(end+1) = obj.gaussianBandwidth(end);
            end
            
            while length(obj.besselOrder) < 2*in.N
                obj.besselOrder(end+1) = obj.besselOrder(end);
            end
            
            while length(obj.besselBandwidth) < 2*in.N
                obj.besselBandwidth(end+1) = obj.besselBandwidth(end);
            end
            
            if ~isempty(obj.userDefinedFilter)
                while size(obj.userDefinedFilter,2) < 2*in.N
                    obj.userDefinedFilter(:,end+1) = obj.userDefinedFilter(:,end);
                end
            end
            
            
            
            
            auxiliarySignal = in.getRaw;
            
            inputSignal = zeros(in.L, 2*in.N);
            for ii = 1:in.N
                inputSignal(:,2*ii-1) = real(auxiliarySignal (:,ii));
                inputSignal(:,2*ii  ) = imag(auxiliarySignal (:,ii));
            end
            clear auxiliarySignal
            
            
            %> User defined filter
            if ~isempty(obj.userDefinedFilter)
                preFilter = zeros(size(inputSignal));
                preFilter(1:length(obj.userDefinedFilter(:,ii)), :) = obj.userDefinedFilter;
                preFilter = fftshift(fft(preFilter),1);
            else
                preFilter = ones(size(inputSignal));
            end
            
            %> Gaussian pre-filtering
            for ii = 1:size(inputSignal,2)
                if obj.gaussianOrder(ii)
                    preFilter(:,ii) = preFilter(:,ii).*exp(log(sqrt(2))*((linspace(-0.5,0.5,size(inputSignal,1))/(obj.gaussianBandwidth(ii)/(in.Fs))).').^(2*obj.gaussianOrder(ii)));
                    preFilter([1:round(length(preFilter)*(0.5-1/in.Nss)) round(length(preFilter)*(0.5+1/in.Nss)):end], ii) = 1;
                end
            end
            
            %> Bessel pre-filtering for group delay
            for ii = 1:size(inputSignal,2)
                if obj.besselOrder(ii)
                    [B,A] = besself(obj.besselOrder(ii), obj.besselBandwidth(ii));
                    besselFilter = polyval(B, in.Fs*2j*pi*linspace(-0.5,0.5,size(inputSignal,1)))./polyval(A, in.Fs*2j*pi*linspace(-0.5,0.5,size(inputSignal,1)));
                    preFilter(:,ii) = preFilter(:,ii).*exp(-1j*angle(besselFilter(:)));
                end
            end
            
            outputSignal = zeros(in.L,in.N);
            
            for ii = 1:in.N
                outputSignal(:,ii) = real(obj.filterByFFT(inputSignal(:,2*ii-1), preFilter(:,2*ii-1))) + 1j*real(obj.filterByFFT(inputSignal(:,2*ii), preFilter(:,2*ii)));
            end
            
            out = in.set(outputSignal);
            
        end
    end
    
    methods (Static)
        function io = filterByFFT(io, filter)
            io = fftshift(fft(io(:)));
            io = ifft(ifftshift(io.*filter(:)));
        end
        
    end
end