%>@file TxPulseShaping_v1.m
%>@brief  Transmitter Pulse Shaping Block
%> 
%>@class TxPulseShaping_v1
%>@brief  Transmitter Pulse Shaping Block
%>
%>
%> This class implements upsampling and pulse shaping.
%>
%> Pulses = TxPulseShaping_v1(param)
%>
%> Set of parameters required to create:
%>
%> @verbatim
%>       param.SamplesPerSymbol      = number of output samples per symbol;
%>       param.SymbolRate            = input symbol rate;
%>       param.Pulse                 = desired pulse shape (check implemented options);
%>       param.RollOff               = required for Nyquist (root-raised cosine) family of pulses;
%>       param.MaxNumberOfSymbols    = maximum number of output symbols ;
%>       param.CarrierFrequency      = defines a carrier frequency associated with the output signal_interface;
%>       param.CarrierPhase          = defines a carrier phase associated with the complex modulated signal;
%>       param.CarrierPower          = defines the carrier power;
%> @endverbatim
%>
%> Traverse syntax : Eout = traverse(obj, Ein)
%>
%> Ein       : signal_interface instance (1 sample/symbol);
%> Eout      : signal_interface instance, resultant train of pulses (with desired number of samples per symbol);
%>
%> Obs. 1: The carrier frequency is only defined for later convenience.
%> The signal still represents the complex equivalent baseband.
%>
%> @author Edson Porto da Silva
classdef TxPulseShaping_v1 < unit
    
    properties
        %> Number of output samples per symbol
        SamplesPerSymbol;
        %> Input symbol rate
        SymbolRate;
        %> Desired pulse shape {'Nyquist' | 'RZ50' | 'RZ33' | 'RZ67' | 'NRZ'}
        Pulse;
        %> Rolloff factor for Nyquist family of pulses
        RollOff;
        DelaySymb;
        %> Maximum number of output symbols
        MaxNumberSymbols;
        %> Carrier frequency associated with the output signal_interface
        CarrierFrequency;
        %> Carrier phase associated with the complex modulated signal;
        CarrierPhase;
        %> Carrier power
        CarrierPower;
        
        nOutputs = 1;
        nInputs = 1;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> See class header for parameter definitions
        function obj = TxPulseShaping_v1(param)
            obj.SamplesPerSymbol   = paramdefault(param,'SamplesPerSymbol',16);
            obj.SymbolRate         = paramdefault(param,'SymbolRate', 32e9);
            obj.Pulse              = paramdefault(param,'Pulse', 'NRZ');
            obj.RollOff            = paramdefault(param,'RollOff', 0.1);
            obj.DelaySymb          = 0;
            obj.CarrierFrequency   = paramdefault(param, 'CarrierFrequency', 193.65e12);
            obj.CarrierPower       = paramdefault(param, 'CarrierPower', 0);
            obj.CarrierPhase       = paramdefault(param, 'CarrierPhase', 0);
            
            
            if isfield(param,'MaxNumberSymbols')
                obj.MaxNumberSymbols = param.MaxNumberSymbols;
            else
                error('\nParameter MaxNumberSymbols not defined.\n');
            end
            
        end
        
        %> @brief Upsamples and filters
        %>
        %> @param in    Input symbol sequence at 1 sample per symbol
        %>
        %> @retval out  Output upsampled symbol sequence
        function Eout = traverse(obj, Ein)
            
            % Get symbols:
            Signal = get(Ein);
            x = Signal(:,1).';                         % Polarization X (Pol.x)
            y = Signal(:,2).';                         % Polarization Y (Pol.y)
            S    = [x; y];
            
            % Upsampling:
            SX_I = upsample(real(S(1,:)),obj.SamplesPerSymbol);
            SX_Q = upsample(imag(S(1,:)),obj.SamplesPerSymbol);
            SY_I = upsample(real(S(2,:)),obj.SamplesPerSymbol);
            SY_Q = upsample(imag(S(2,:)),obj.SamplesPerSymbol);
            
            % Pulseshaping for baseband signal representation:
            
            % Nyquist:
            switch obj.Pulse
                case 'Nyquist'
                    %Hd = design(fdesign.interpolator(obj.SamplesPerSymbol,'Raised Cosine',obj.SamplesPerSymbol,'Ast,Beta',10,obj.RollOff));
                    Hd = design(fdesign.interpolator(obj.SamplesPerSymbol,'Square Root Raised Cosine',obj.SamplesPerSymbol,'Ast,Beta',10,obj.RollOff));
                    
                    SX_I = filter(Hd.Numerator,1,SX_I);
                    SX_Q = filter(Hd.Numerator,1,SX_Q);
                    SY_I = filter(Hd.Numerator,1,SY_I);
                    SY_Q = filter(Hd.Numerator,1,SY_Q);
                    
                    SX = SX_I+1i*SX_Q;
                    SY = SY_I+1i*SY_Q;
                    
                    PowNormFacX = sum(abs(SX).^2)/length(SX);
                    PowNormFacY = sum(abs(SY).^2)/length(SY);
                    SX = SX/sqrt(PowNormFacX);
                    SY = SY/sqrt(PowNormFacY);
                    
                    SX = SX(length(Hd.Numerator):end);
                    SY = SY(length(Hd.Numerator):end);
                    %fprintf('Number of Raised Cosine filter coefficients: %d\n', length(Hd.Numerator))
                    obj.DelaySymb = ceil(length(Hd.Numerator)/obj.SamplesPerSymbol);
                    
                case 'RZ50'
                    fa = 1/obj.SamplesPerSymbol;
                    t = [0:fa:1];
                    p_RZ50 = cos(pi/4*sin(2*pi*t-pi/2)-pi/4);
                    
                    SX_I = filter(p_RZ50,1,SX_I);
                    SX_Q = filter(p_RZ50,1,SX_Q);
                    SX = SX_I+1i*SX_Q;
                    
                    SY_I = filter(p_RZ50,1,SY_I);
                    SY_Q = filter(p_RZ50,1,SY_Q);
                    SY = SY_I+1i*SY_Q;
                    
                    PowNormFacX = sum(abs(SX).^2)/length(SX);
                    PowNormFacY = sum(abs(SY).^2)/length(SY);
                    SX = SX/sqrt(PowNormFacX);
                    SY = SY/sqrt(PowNormFacY);
                    
                    SX = SX(length(p_RZ50):end);
                    SY = SY(length(p_RZ50):end);
                    obj.DelaySymb = ceil(length(p_RZ50)/obj.SamplesPerSymbol);
                    
                case 'RZ33'
                    fa = 1/obj.SamplesPerSymbol;
                    t = [0:fa:1];
                    p_RZ33 = cos(pi/2*sin(pi*t-pi/2)-0);
                    
                    SX_I = filter(p_RZ33,1,SX_I);
                    SX_Q = filter(p_RZ33,1,SX_Q);
                    SX = SX_I+1i*SX_Q;
                    
                    SY_I = filter(p_RZ33,1,SY_I);
                    SY_Q = filter(p_RZ33,1,SY_Q);
                    SY = SY_I+1i*SY_Q;
                    
                    PowNormFacX = sum(abs(SX).^2)/length(SX);
                    PowNormFacY = sum(abs(SY).^2)/length(SY);
                    SX = SX/sqrt(PowNormFacX);
                    SY = SY/sqrt(PowNormFacY);
                    
                    SX = SX(length(p_RZ33):end);
                    SY = SY(length(p_RZ33):end);
                    obj.DelaySymb = ceil(length(p_RZ33)/obj.SamplesPerSymbol);
                    
                case 'RZ67'
                    fa = 1/obj.SamplesPerSymbol;
                    t = [0:fa:1];
                    p_RZ67 = cos(pi/2*sin(pi*t-0)-pi/2);
                    
                    SX_I = filter(p_RZ67,1,SX_I);
                    SX_Q = filter(p_RZ67,1,SX_Q);
                    SX = SX_I+1i*SX_Q;
                    clear SX_I SX_Q
                    
                    SY_I = filter(p_RZ67,1,SY_I);
                    SY_Q = filter(p_RZ67,1,SY_Q);
                    SY = SY_I+1i*SY_Q;
                    clear SY_I SY_Q
                    
                    PowNormFacX = sum(abs(SX).^2)/length(SX);
                    PowNormFacY = sum(abs(SY).^2)/length(SY);
                    SX = SX/sqrt(PowNormFacX);
                    SY = SY/sqrt(PowNormFacY);
                    
                    SX = SX(length(p_RZ67):end);
                    SY = SY(length(p_RZ67):end);
                    obj.DelaySymb = ceil(length(p_RZ67)/obj.SamplesPerSymbol);
                    
                case 'NRZ'
                    p_NRZ = [1 ones(1,obj.SamplesPerSymbol)];
                    
                    SX_I = filter(p_NRZ,1,SX_I);
                    SX_Q = filter(p_NRZ,1,SX_Q);
                    SX = SX_I+1i*SX_Q;
                    clear SX_I SX_Q
                    
                    SY_I = filter(p_NRZ,1,SY_I);
                    SY_Q = filter(p_NRZ,1,SY_Q);
                    SY = SY_I+1i*SY_Q;
                    clear SY_I SY_Q
                    
                    PowNormFacX = sum(abs(SX).^2)/length(SX);
                    PowNormFacY = sum(abs(SY).^2)/length(SY);
                    SX = SX/sqrt(PowNormFacX);
                    SY = SY/sqrt(PowNormFacY);
                    
                    SX = SX(length(p_NRZ):end);
                    SY = SY(length(p_NRZ):end);
                    obj.DelaySymb = ceil(length(p_NRZ)/obj.SamplesPerSymbol);
                    
                case 'ISI-free-Polinomial'
                    warning('\n This option (ISI-free-Polinomial pulses) was not tested. It should not work.')
                    fa = 1/obj.SamplesPerSymbol;
                    t = [0:fa:1];
                    p_pol = cos(2*pi*t).*sinc(2*t).*(sinc(t).^2-sinc(2*t))./(pi*t).^2;
                    
                    SX_I = filter(p_pol,1,SX_I);
                    SX_Q = filter(p_pol,1,SX_Q);
                    SX = SX_I+1i*SX_Q;
                    
                    SY_I = filter(p_pol,1,SY_I);
                    SY_Q = filter(p_pol,1,SY_Q);
                    SY = SY_I+1i*SY_Q;
                    
                    PowNormFacX = sum(abs(SX).^2)/length(SX);
                    PowNormFacY = sum(abs(SY).^2)/length(SY);
                    SX = SX/sqrt(PowNormFacX);
                    SY = SY/sqrt(PowNormFacY);
                    
                    SX = SX(length(p_pol):end);
                    SY = SY(length(p_pol):end);
                    obj.DelaySymb = ceil(length(p_pol)/obj.SamplesPerSymbol);
                otherwise
                    error('\nRequired pulse shape is not supported.')
                    
            end
            
            
            % Phase shift:
            SX = SX*exp(1i*obj.CarrierPhase);
            SY = SY*exp(1i*obj.CarrierPhase);
            
            % Power adjustment:
            P_pol = 10^(obj.CarrierPower/10)*1e-3/2;     % Convert dBm to W and divide by 2 to get power per polarization (assuming equal splitting)
            SX = sqrt(P_pol)*SX;
            SY = sqrt(P_pol)*SY;
            
            if obj.MaxNumberSymbols > length(SX)/obj.SamplesPerSymbol
                error('Number of samples is not enougth to provide the specified number of output symbols.')
            else
                Spulse = [SX(1:obj.MaxNumberSymbols*obj.SamplesPerSymbol); SY(1:obj.MaxNumberSymbols*obj.SamplesPerSymbol)];
            end
            
            % Power measurement:
            Psig = sum(abs(SX).^2 + abs(SY).^2)/length(SX);
            Psig_dBm = 10*log10(Psig/1e-3);
            
            % Output field:
            Eout = signal_interface(Spulse.',struct('Fs',obj.SymbolRate*obj.SamplesPerSymbol,'Fc',obj.CarrierFrequency,'Rs',obj.SymbolRate,'P',pwr(Inf,Psig_dBm)));
        end
        
    end
end
