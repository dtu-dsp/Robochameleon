%> @file PulseTrainGenerator_v1.m
%> @brief Generates train of pulses with different shapes

%>@class PulseTrainGenerator_v1
%>@brief Generates train of pulses with different shapes
%> 
%> Supported pulse shapes:
%>
%> - rect - Rectangular
%> - gaussian - Gaussian
%> - sech - Hyperbolic secant
%> - rcos - Raised cosine
%> - rrcos - Root raised cosine
%>
%> __Example__
%> @code
%> param.ptg.avgPower    = 0;
%> param.ptg.nPulses     = 3;
%> param.ptg.Rs          = 10e9;
%> param.ptg.Fs          = 160e9;
%> param.ptg.wavelength  = 1550.3;
%> param.ptg.shape       = 'gaussian'; % gaussian rect nyquist
%> param.ptg.T0          = 1/param.ptg.Rs*0.2;
%> ptg = PulseTrainGenerator_v1(param.ptg);
%> sig = ptg.traverse();
%> @endcode
%>
%> See run_TestPulseTrainGenerator_v1 to see some usage examples
%>
%> __Note__
%> filterSpanLength - 
%> In a symbol period we have the pulse and the tails of the
%> adjacent pulses, so that the train is the result of the sum of all these things.
%> If the pulse is broad compared to the symbol period the effect of the tails is significant, so we may need
%> to use an higher number of filterSpanLength to correctly obtain the train
%>
%> @author Simone Gaiarin
%>
%> @version 1
classdef PulseTrainGenerator_v1 < unit
    
    properties
    %> Number of inputs
    nInputs = 0;
    %> Number of outputs
    nOutputs = 1;
    %> Pulse shape
    shape;
    %> Samplig frequency
    Fs;
    %> Symbol rate
    Rs;
    %> Samples per symbol
    Nss;
    %> Wavelength
    wavelength = 1550;
    %> The data sequence to which the filter will be applied
    data;
    %> Number of pulses
    nPulses;
    %> Peak power
    peakPower = 1;
    %> Average power
    avgPower;
    %> Duty cycle of the pulse defined as FWHM/Ts
    dutyCycle;
    %> HW @ 1/e intensity (E^2)
    T0;
    %> Length of shaping filter in number of symbol periods
    filterSpanLength = 2;
    %> Rise time for shaped rect pulses
    riseTime = 0;
    %> Rolloff factor for raised cosine shaped rect pulses
    rolloff;
    
    end
    
    methods
    
        %> @brief Class constructor
        %>
        %> Constructs an object of type ClassTemplate_v1 and more information..
        %> Don't put example here, since we have it in the description..
        %>
        %> @param param.shape          Shape of the filter. Possible values = {'rect', 'sech', 'gaussian',
        %>                             'rect.gaussian', 'rect.rcos'}
        %> @param param.Fs             Sampling frequency (Only two among Fs, Rs and Nss are required)
        %> @param param.Rs             Symbol rate  (Only two among Fs, Rs and Nss are required)
        %> @param param.Nss            Samples per symbol  (Only two among Fs, Rs and Nss are required)
        %> @param wavelength           Wavelength [nm]. Default: 1550
        %> @param param.data           The data sequence to which the filter will be applied. Example
        %>                             [1 1 0 -1] (Alternative to param.nPulses
        %> @param param.nPulses        The number of pulses. (Alternative to param.data). data will be set to
        %>                             a train of ones
        %> @param param.peakPower      The peak power of the largest of the pulses in the train. (Alternative
        %>                             to avgPower. Default: 1.
        %> @param param.avgPower       The average power of the train of pulses. If not specified the
        %>                             peakPower will be used
        %> @param param.rolloff        Rolloff of rcos and rrcos filters
        %> @param param.dutyCycle      Duty cycle of the pulse defined as FWHM/Ts
        %> @param param.T0             HW @ 1/e intensity (E^2). Alternatived to power.dutyCycle
        %> @param param.filterSpanLength Length of shaping filter in number of symbol periods. Default:2
        %> @param param.risetime       Rise time for shaped rect pulses
        %> @param param.rolloff        Rolloff factor for raised cosine shaped rect pulses
        function obj = PulseTrainGenerator_v1(param)
            param = setParamFsRssNss(param);
            param = obj.setParamT0DutyCycle(param);
            REQUIRED_PARAMS = {'shape'};
            obj.setparams(param, REQUIRED_PARAMS);
            if mod(obj.Nss*obj.filterSpanLength, 2)
                robolog('If Nss is odd, filterSpanLength must be even.', 'ERR');
            end
        end
        
        %> @brief Compute T0 from dutyCycle or viceversa
        %>
        %> @param inParam Parameter structure containing either T0 or dutyCycle
        %>
        %> @retval param Parameter structure containing both T0 and dutyCycle (computed one from another)
        function param = setParamT0DutyCycle(obj, inParam)
            param = inParam;
            if ~isfield(param, 'T0') && ~isfield(param, 'dutyCycle')
                robolog('Need to specify at least one between T0 and duty cycle.', 'ERR');
            elseif ~isfield(param, 'T0')
                Ts = 1/param.Rs;
                TFWHM = param.dutyCycle*Ts;
                param.T0 = TFWHM/(2*sqrt(log(2)))
                robolog('Computing T0 from duty cycle');
            elseif ~isfield(param, 'dutyCycle')
                Ts = 1/param.Rs;
                param.dutyCycle = 2*param.T0/Ts;
                robolog('Computing duty cycle from T0');
            else
                robolog('Cannot specify both T0 and duty cycle.', 'ERR');
            end
            if param.dutyCycle > 1
                robolog('Duty cycle cannot exceed 1', 'ERR');
            end
        end
        
        %> @brief Generate the shaping pulse shape from the parameters and the shaping type
        %>
        %> @param pulseShape The type of pulse shaping. Possible values: {'rect', sech', 'gaussian', rcos', rrcos'}
        %>
        %> @retval pshape Waveform of the desired pulse shape
        function pshape = genPulseShape(obj, pulseShape, Nss)
            switch lower(pulseShape)
                case 'rect'
                    %Create a symmetrical rect shape (adds one symbol if needed) Is it correct?
                    nones = round(obj.dutyCycle*Nss);
                    halfnzeros = ceil((obj.filterSpanLength*Nss - nones)/2);
                    pshape = [zeros(halfnzeros, 1); rectpulse(1, nones); zeros(halfnzeros, 1)];
                case 'sech'
                    t = -obj.filterSpanLength/(2*obj.Rs):1/obj.Fs:(obj.filterSpanLength/(2*obj.Rs) - 1/obj.Fs);
                    % At x = 1.0850 the intensity of a sech is 1/e its maximum
                    pshape = sech(1.0850*t./obj.T0);
                case 'gaussian'
                    Ts = 1/obj.Rs;
                    bt = 0.5*sqrt(log(2))*Ts/(pi*obj.T0);
                    pshape = gaussdesign(bt, obj.filterSpanLength, Nss);
                case 'rcos'
                    pshape = rcosdesign(obj.rolloff, obj.filterSpanLength, Nss);
                case 'rrcos'
                    pshape = rcosdesign(obj.rolloff, obj.filterSpanLength, Nss, 'sqrt');
                otherwise
                    robolog('Pulse shape NOT supported', 'ERR');
            end
        end
       
        %> @brief Generate a pulse train with the give pulse shape
        function sig = traverse(obj)
            if isempty(obj.data)
                obj.data = ones(1, obj.nPulses);
            else
                obj.nPulses = numel(obj.data);
            end
            tokens =  strsplit(obj.shape, '.');
            pulseShape = cell2mat(tokens(1));
            if length(tokens) > 1
                filterType = cell2mat(tokens(2));
            end
            pshape = obj.genPulseShape(pulseShape, obj.Nss);
            train = upfirdn(obj.data, pshape, obj.Nss);
            halfCutLength = floor(0.5*(obj.filterSpanLength-1)*obj.Nss);
            train = train(1+halfCutLength:end-halfCutLength-mod(length(train),2));
            if ~isempty(strfind(obj.shape, 'rect')) && exist('filterType', 'var')
                obj.data = train;
                if strcmp(filterType, 'gaussian')
                    %WAY 1: Compute new T0 to guaranteed given rise time
                    %WAY 2: Change Nss as a function of rise time
                    T0 = 0.5*obj.T0*obj.riseTime; %WAY 1
                    %T0 = obj.T0 % WAY 2
                    Ts = 1/obj.Rs;
                    bt = 0.5*sqrt(log(2))*Ts/(pi*T0);
                    pshape = gaussdesign(bt, obj.filterSpanLength, obj.Nss); %WAY 1
                    %pshape = gaussdesign(bt, obj.filterSpanLength, round(obj.riseTime*obj.Nss)); %WAY 2
                elseif strcmp(filterType, 'rcos')
                    pshape = rcosdesign(obj.rolloff, obj.filterSpanLength, round(obj.riseTime*obj.Nss));
                    robolog('Buggy implementation. Two pulses are cut out', 'WRN');
                else
                    robolog('Filter type not supported', 'ERR');
                end
                train = upfirdn(obj.data, pshape);
                halfCutLength = floor((obj.filterSpanLength-1)*obj.Nss);
                train = train(1+halfCutLength:end-halfCutLength-mod(length(train),2));
            end
            
            %Pulse cutting needs fixing
            %pshape of gaussian is always symmetric and is long Nss+1
            %pshape of rect is always symmetric but its length can be Nss or Nss+1 depending on
            %rounding of duty cycle and Nss
            if isempty(obj.avgPower)
                train = train*sqrt(obj.peakPower)/max(train);
                obj.avgPower = 10*log10(pwr.meanpwr(train)*1000);
            end
            
            sig_param = struct('Rs',obj.Rs,'Fs',obj.Fs, ...
                'Fc',const.c/(obj.wavelength*1e-9),'P',pwr(inf,obj.avgPower));
            sig = signal_interface(train,sig_param);
        end
    end
end
