%>@file ElectricalFilter_v1.m
%>@brief ElectricalFilter_v1 Electrical filtering of a driver device.
%>
%>@class ElectricalFilter_v1
%>@brief ElectricalFilter_v1 Electrical filtering of a driver device.
%>
%> This function simulates a driver device. It performs electrical filtering
%> of the signal and simulates group delay, amplitude imbalance and DC level
%> insertion.
%>
%> __Observations__
%> The input signal shall be a complex signal_interface signal.
%>
%> __Example__
%> @code
%>   % Here we put a FULLY WORKING example using the MINIMUM set of required parameters
%>    param.sig.Fs = 64e9;
%>    param.sig.Fc = 0;
%>    param.sig.Rs = 32e9;
%>    Ein = upsample((randi(2,10000,1)-1.5)*2 + 1j*(randi(2,10000,1)-1.5)*2,2);
%>    signal_in = signal_interface(Ein, param.sig);
%>
%>    param.drivers.rectangularFilter = false;
%>    param.drivers.gaussianOrder = false;
%>    param.drivers.besselOrder = false;
%>    drivers = ElectricalFilter_v1(param.drivers);
%>    signal_out = drivers.traverse(signal_in);
%> @endcode
%>
%> __Advanced Example__
%> @code
%>   % Here we put a FULLY WORKING example using the MAXIMUM set of required parameters
%>    param.sig.Fs = 64e9;
%>    param.sig.Fc = 0;
%>    param.sig.Rs = 32e9;
%>    Ein = upsample((randi(2,10000,1)-1.5)*2 + 1j*(randi(2,10000,1)-1.5)*2,2);
%>    signal_in = signal_interface(Ein, param.sig);
%>
%>    param.drivers.rectangularFilter = true;
%>    param.drivers.rectangularBandwidth = 40e9;
%>    param.drivers.gaussianOrder = 2;
%>    param.drivers.gaussianBandwidth = 18e9;
%>    param.drivers.besselOrder = 1;
%>    param.drivers.besselBandwidth = 110e9;
%>    param.drivers.outputVoltage = [2.0]; %Volts
%>    param.drivers.amplitudeImbalance = [0.9 1.1];
%>    param.drivers.levelDC = [0.5 0]; %Volts
%>    drivers = ElectricalFilter_v1(param.drivers);
%>    signal_out = drivers.traverse(signal_in);
%> @endcode
%>
%> @author Júlio Diniz
%> @version 1
classdef ElectricalFilter_v1 < unit
    
    properties
        %> Number of outputs
        nOutputs = 1;
        %> Number of inputs
        nInputs = 1;
        %> Turn ON Rectangular Filter?
        rectangularFilter = false;
        %> Bandwidth of Rectangular Filter
        rectangularBandwidth;
        %> Order of Gaussian Filter (Equals zero to turn OFF)
        gaussianOrder = 0;
        %> Bandwidth of gaussian Filter
        gaussianBandwidth;
        %> Order of Bessel Filter (Equals zero to turn OFF)
        besselOrder = 0;
        %> Bandwidth of Bessel Filter
        besselBandwidth;
        %> Output Voltage
        outputVoltage = 1;
        %> AmplitudeImbalance
        amplitudeImbalance = 1;
        %> DC level
        levelDC = 0;
        
    end
    
    methods
        %>@brief Class constructor
        %> @param param.rectangularFilter       Turn ON or OFF the rectangular time-domain filtering. True = ON / False = OFF.
        %>                                                        
        %> @param param.rectangularBandwidth    Baseband bandwidth of rectangular filter.
        %> @param param.gaussianOrder           The order of frequency-domain gaussian filter. Turn OFF = 0 (zero) / Turn ON = any other positive number.
        %> @param param.gaussianBandwidth       Baseband bandwidth of gaussian filter.
        %> @param param.besselOrder             The order of frequency-domain bessel filter for group delay simulation. Turn OFF = 0 (zero) / Turn ON = any other positive integer.
        %> @param param.besselBandwidth         Baseband bandwidth of bessel filter.
        %> @param param.outputVoltage           Output peak voltage before DC level insertion.
        %> @param param.amplitudeImbalance      A vector containing amplitude imbalance for each output. E.g. if outputVoltage = 2, and amplitude imbalance equals to [1 0.9 1.1 0.8], so, the output peak voltage will be 2, 1.8, 2.2, and 1.6 for I1, Q1, I2, and Q2, respectively.                                               
        %> @param param.levelDC                 A vector containing DC levels to be added to each of in-phase and quadrature signals.
        %>
        function obj = ElectricalFilter_v1(param)
            
            obj.setparams(param, {}, {'besselOrder','gaussianOrder','rectangularFilter', 'outputVoltage', 'amplitudeImbalance', 'levelDC','rectangularBandwidth', 'gaussianBandwidth', 'besselBandwidth'})
            
            if isempty(obj.gaussianBandwidth) && obj.gaussianOrder
                robolog('As "param.gaussianOrder ~=0", so you should define "param.gaussianBandwidth" for ElectricalFilter.', 'ERR');
            end
            
            if isempty(obj.besselBandwidth) && obj.besselOrder
                robolog('As "param.besselOrder ~=0", so you should define "param.besselBandwidth" for ElectralFilter.', 'ERR');
            end
            
            if isempty(obj.rectangularBandwidth) && obj.rectangularFilter
                robolog('As "param.rectangularFilter == true", so you should define "param.rectangularBandwidth" for ElectricalFilter.', 'ERR')
            end
            
        end
        
        function out = traverse(obj, in)
            
            %% Driver Filtering
            % Rectangular Filter
            if obj.rectangularFilter
                rectCoeffs = (2*obj.rectangularBandwidth/(in.Fs))*sinc(2*in.Nss*(obj.rectangularBandwidth/(in.Fs))*linspace(-101, 101, (in.Nss)*202+1)).';
                in = in.fun1(@(x) obj.filterByConv(x, rectCoeffs));
            end
            
            filterFreqDomain = 1;
            % Gaussian Filter
            if obj.gaussianOrder
                filterFreqDomain = filterFreqDomain.*exp(-log(sqrt(2))*((linspace(-0.5,0.5,in.L)/(obj.gaussianBandwidth/(in.Fs))).').^(2*obj.gaussianOrder));
            end
            % Bessel Filter
            if obj.besselOrder
                [B,A] = besself(obj.besselOrder, obj.besselBandwidth);
                besselFilter = polyval(B, in.Fs*2j*pi*linspace(-0.5,0.5,in.L))./polyval(A, in.Fs*2j*pi*linspace(-0.5,0.5,in.L));
                filterFreqDomain = filterFreqDomain.*exp(1j*angle(besselFilter(:)));
            end
            in = in.fun1(@(x) obj.filterByFFT(x, filterFreqDomain));
            
            %% Driver Amplitude
            outputSignal = in.getRaw; 
            % Test of parameters lengths match
            if length(obj.amplitudeImbalance) == 1
                obj.amplitudeImbalance(2) = obj.amplitudeImbalance(1);
            end
            if length(obj.amplitudeImbalance) < 2*size(outputSignal,2)
                for ii = floor(length(obj.amplitudeImbalance)/2)+1:size(outputSignal,2)
                    obj.amplitudeImbalance(2*ii-1) = obj.amplitudeImbalance(2*ii-3);
                    obj.amplitudeImbalance(2*ii  ) = obj.amplitudeImbalance(2*ii-2);
                end
            end
            if length(obj.levelDC) == 1
                obj.levelDC(2) = obj.levelDC(1);
            end
            if length(obj.levelDC) < 2*size(outputSignal,2)
                for ii = floor(length(obj.levelDC)/2)+1:size(outputSignal,2)
                    obj.levelDC(2*ii-1) = obj.levelDC(2*ii-3);
                    obj.levelDC(2*ii  ) = obj.levelDC(2*ii-2);
                end
            end
            
            
            % Output Voltage Driver
            maxVoltage = max(max(abs([real(outputSignal) imag(outputSignal)])));
            for ii = 1:size(outputSignal,2)
                outputSignal(:,ii) = (obj.amplitudeImbalance(2*ii-1)*real(outputSignal(:,ii)) + 1j*obj.amplitudeImbalance(2*ii)*imag(outputSignal(:,ii)))*obj.outputVoltage/maxVoltage;
                outputSignal(:,ii) = outputSignal(:,ii) + obj.levelDC(2*ii-1) + 1j*obj.levelDC(2*ii);
            end
            
            % Power Computer
            P = pwr.meanpwr(outputSignal);
            for ii = length(P):-1:1
                Power{ii} = pwr(in.PCol(ii).SNR, {P(ii), 'w'});
            end
            
            % Set signal_interface output
            out = signal_interface(outputSignal, struct('Rs', in.Rs, 'Fs', in.Fs, 'Fc', in.Fc, 'PCol', [Power{:}]));
            
        end
    end
    methods (Static)
        function io = filterByFFT(io, filter)
            io = fftshift(fft(io(:)));
            io = ifft(ifftshift(io.*filter(:)));
        end
        function io = filterByConv(io,filterCoeffs)
            io = conv(io, filterCoeffs, 'same');
        end
        
    end
end