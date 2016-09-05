%>@file PulseShaper_v1.m
%>@brief PulseShaper_v1 Pulse shaper.
%>
%>@class PulseShaper_v1
%>@brief PulseShaper_v1 Pulse shaper.
%>
%> This function converts the input signal in an upsampled pulse shaped signal.
%>
%> __Observations__
%>
%>   The input signal shall be an 1 sample per symbol complex signal_interface signal.
%>
%>   'rc'   - Raised Cosine, a.k.a. Nyquist Shaping (when using rollOff = 0).
%>   'rrc'  - Root Raised Cosine.
%>   'nrz'  - Non Return to Zero.
%>   'rz33' - Return to Zero with 1/3 duty cycle.
%>   'rz50' - Return to Zero with 1/2 duty cycle.
%>   'rz66' - Return to Zero with 2/3 duty cycle.
%>
%> __Example__
%> @code
%>   % Here we put a FULLY WORKING example using the MINIMUM set of required parameters
%>   param.ps.samplesPerSymbol = 8;
%>   param.ps.pulseShape = 'rz33';
%>   pulseshaper = PulseShaper_v1(param.quantizer);
%>
%>   param.sig.Fs = 32e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = upsample((randi(2,10000,1)-1.5)*2 + 1j*(randi(2,10000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = pulseshaper.traverse(sigIn);
%> @endcode
%>
%> __Advanced Example__
%> @code
%>   % Here we put a FULLY WORKING example using the MINIMUM set of required parameters
%>   param.ps.samplesPerSymbol = 8;
%>   param.ps.pulseShape = 'rc';
%>   param.ps.rollOff = 0.1;
%>   param.ps.filterSymbolLength = 101;
%>   pulseshaper = PulseShaper_v1(param.quantizer);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 0;
%>   param.sig.Rs = 32e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = upsample((randi(2,10000,1)-1.5)*2 + 1j*(randi(2,10000,1)-1.5)*2,2);
%>   sigIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = pulseshaper.traverse(sigIn);
%> @endcode
%>
%> @author Júlio Diniz
%> @version 2
classdef PulseShaper_v1 < unit
    
    properties (Access = public)
        %> Number of outputs
        nOutputs = 1;
        %> Number of inputs
        nInputs = 1;
        %> Output samples per symbol
        samplesPerSymbol;
        %> Output sample rate (Does not need to be defined) [Default 1]
        symbolRate = 1;
        %> Pulse shaping
        pulseShape;
        %> Symbol length of Raised Cosine or Root Raised Cosine filters
        filterSymbolLength = 202;
        %> Rolloff for Raised Cosine or Root Raised Cosine filters
        rollOff;
    end
    properties (Access = private)
        %> Filter Coefficients
        filterCoeffs;
    end
    methods
        %> @brief Class constructor.
        %>
        %> @param param.samplesPerSymbol   SamplesPerSymbol - It is the desired output number of samples per symbol.
        %> @param param.pulseShape         PulseShape - Choose among 'rc', 'rrc', 'rz33%', 'rz50%', 'rz67%', 'nrz' or 'custom';
        %> @param param.filterCoeffs       FilterCoeffs - You should define this as a vector if you chose 'custom' 'pulseShape'.
        %> @param param.filterSymbolLength FilterSymbolLength - You should define a symbol length for 'rc' or 'rrc' filters. The default value is 202.
        %> @param param.rollOff            RollOff - The Roll-Off factor. You should define this value if you are using 'rc' or 'rrc' shapings. Usually, this number varies from 0 to 1.
        %> @param param.symbolRate         SymbolRate - You are able to define a symbol rate for your signal here. The output sample frequency will be define as symbolRate*samplesPerSymbol.
        %>
        %> @retval obj      An instance of the class PulseShaper_v1.
        function obj = PulseShaper_v1(param)
            obj.setparams(param,{'pulseShape','samplesPerSymbol'},{'symbolRate','filterSymbolLength'})

            if (mod(min(obj.samplesPerSymbol),1) ~= 0) || (obj.samplesPerSymbol == 0) || (length(obj.samplesPerSymbol) ~= 1)
                robolog('The property "samplesPerSymbol" should be an interger greater than zero.', 'ERR')
            end            
            
            switch lower(obj.pulseShape)
                case 'rz33'
                    obj.filterCoeffs = cos((pi/2)*sin(pi*(0:(1/obj.samplesPerSymbol):1)-pi/2));
                case 'rz50'
                    obj.filterCoeffs = cos((pi/4)*sin(2*pi*(0:(1/obj.samplesPerSymbol):1)-pi/2)-pi/4);
                case 'rz66'
                    obj.filterCoeffs = cos((pi/2)*sin(pi*(0:(1/obj.samplesPerSymbol):1))-pi/2);
                case 'nrz'
                    obj.filterCoeffs = ones(1,obj.samplesPerSymbol);
                case 'rc'
                    if ~isfield(param, 'rollOff') 
                        robolog('Please set a roll-off factor', 'ERR')
                    end
                    filterFreqs = linspace(-(obj.filterSymbolLength/2), (obj.filterSymbolLength/2), obj.samplesPerSymbol*obj.filterSymbolLength+1);
                    obj.filterCoeffs = sinc(filterFreqs).*cos(pi*obj.rollOff*filterFreqs)./(1-4*obj.rollOff^2*filterFreqs.^2);
                    obj.filterCoeffs(abs(filterFreqs) == 1/(2*obj.rollOff)) = (pi/4)*sinc(1/(2*obj.rollOff));
                case 'rrc'
                    if ~isfield(param, 'rollOff') 
                        robolog('Please set a roll-off factor', 'ERR')
                    end
                    filterFreqs = linspace(-(obj.filterSymbolLength/2), (obj.filterSymbolLength/2), obj.samplesPerSymbol*obj.filterSymbolLength+1);
                    obj.filterCoeffs = (sin(pi*filterFreqs*(1-obj.rollOff)) + 4*obj.rollOff*filterFreqs.*cos(pi*filterFreqs*(1+obj.rollOff)))./(pi*filterFreqs.*(1-(4*obj.rollOff*filterFreqs).^2));
                    obj.filterCoeffs(abs(filterFreqs) == 1/(4*obj.rollOff)) = (obj.rollOff/sqrt(2))*( (1+2/pi)*sin(pi/(4*obj.rollOff)) + (1-2/pi)*cos(pi/(4*obj.rollOff)));
                    obj.filterCoeffs(filterFreqs == 0) = 1 - obj.rollOff + 4*obj.rollOff/pi;
                otherwise
                    robolog('Please, define one of the allowed pulse shapes ("NRZ", "RZ33", "RZ50", "RZ67", "RC" or "RRC".', 'ERR')
            end
        end
        
        function out = traverse(obj, in)
            %> @brief Class traverse function.
            out = in.fun1(@(x) obj.ps(x, obj.samplesPerSymbol, obj.filterCoeffs));
            out = set(out, 'Rs', obj.symbolRate, 'Fs', obj.samplesPerSymbol*obj.symbolRate);
        end
    end
    methods (Static)
        function out = ps(in, samplesPerSymbol, filterCoeffs)
           % Upsampling
           in = upsample(in, samplesPerSymbol);
           % Shaping
           out = conv([in(:) ; in(1:10,1)], filterCoeffs, 'same');
           % truncating
           out = out(1:length(in));
        end
    end
    
    
end
