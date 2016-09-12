%> @file SimpleWDMTransmitter_v1.m
%> @brief Simple WDM transmitter class implementation.

%>@class SimpleWDMTransmitter_v1
%>@brief Simple WDM transmitter
%>
%> This is a simple WDM transmitter which contains nChannels simple coherent transmitters.
%> 
%> __Example__
%> 
%> @code
%> %General WDM channel
%> %see setupts/UnitsTesting/run_TestSimpleWDMTransmitter.m
%> carrier_freqs = [-4 4 -2 2 0]*35e9 + 193.4e12;
%> param.nChannels = length(carrier_freqs);;
%> param.lambda = mat2cell(1e9*const.c./carrier_freqs, 1, ones(1,param.nChannels));
%> 
%> %Data paramters
%> param.modulationFormat = 'QAM';
%> param.M = 16;
%> param.pulseShape = 'rrc';
%> param.rollOff = 0.1;
%> param.L  = 1000000/8;
%> param.N = 2;
%> param.samplesPerSymbol = 4;
%> 
%> Tx1 = SimpleWDMTransmitter_v1(param);
%> TxSignal = traverse(Tx1);
%>
%> @endcode
%> 
%> Notes:
%> -# The output signal TxSignal will have a number of samples per symbol of 
%> @code param.samplesPerSymbol * param.upsamplingRate = 16 @endcode in this 
%> example.  @code param.samplesPerSymbol @endcode  goes to the block 
%> PulseShaper_v2, which  is a lab-usable pulse shaping filter.
%> @code param.upsamplingRate @endcode goes to the block DAC_v1, which is a
%> realistic DAC model.
%> -# Any parameters that vary by channel must be passed as a cell array
%> -# Order of operations affects the center frequency when combining channels 
%> together - specify center frequencies/wavelengths from outer to inner or
%> inner to outer (not lowest-highest or highest-to-lowest).
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef SimpleWDMTransmitter_v1 < module

    properties(Access=public)
        %> Number of inputs
        nInputs = 0;
        %> Number of outputs
        nOutputs = 1;
        %> Number of WDM channels
        nChannels;
        %> Wavelengths of the every channel [nm]
        lambda;
        %> Laser linewidth of every channel
        linewidth;
        %> Power of every channel [pwr() obj]
        Power;
        %> Modulation format of every channel
        modulationFormat;
        %> Modulation order of every channel
        M;
        %> Pulseshape of every channel
        pulseShape;
        %> Roll-Off factor of every channel
        rollOff;
        %> FM noise PSD length of Laser, due to double naming of L
        Laser_L;
        %> Combined, concatinated output or both [comb|concat|both]
        output = 'comb';
    end
    
    properties(Access=protected)
       flag = 'Simple';
    end

    methods

        %> @brief Class constructor
        %>
        %> Constructs an object of type SimpleWDMTransmitter_v1.
        %> It also constructs nChannels SimpleCoherentTransmitter_v1.
        %>
        %> @param param.nChannels                     Number of WDM channels
        %> @param param.lambda                        Wavelengths of the every channel [nm] if this parameter is a cell array
        %> @param param.linewidth                     Laser linewidth of every channel if this parameter is a cell array
        %> @param param.modulationFormat              Modulation format of every channel if this parameter is a cell array
        %> @param param.M                             Modulation order of every channel if this parameter is a cell array
        %> @param param.pulseShape                    Pulseshape of every channel if this parameter is a cell array
        %> @param param.rollOff                       Roll-Off factor of every channel if this parameter is a cell array
        %>
        %> SimpleAWG_v1 - WaveformGenerator_v1
        %> @param param.L                             Output sequence length [symbols].
        %> @param param.typePattern                   Type of Pattern. Can be 'PRBS' or 'Random'.
        %> @param param.PRBSOrder                     Polynomial order (any integer 2-23; 27, 31)
        %> @param param.modulationFormat              Modulation format if all channels have equal setup
        %> @param param.M                             Modulation order if all channels have equal setup
        %> @param param.N                             Number of Modes (or polarizations)
        %> @param param.samplesPerSymbol              It is the desired output number of samples per symbol.
        %> @param param.symbolRate                    You are able to define a symbol rate for your signal here. The output sample frequency will be define as symbolRate*samplesPerSymbol.
        %> @param param.pulseShape                    Choose among 'rc', 'rrc', 'rz33%', 'rz50%', 'rz67%', 'nrz' or 'custom' if all channels have equal setup
        %> @param param.filterCoeffs                  You should define this as a vector if you chose 'custom' 'pulseShape'.
        %> @param param.filterSymbolLength            You should define a symbol length for 'rc' or 'rrc' filters. The default value is 202.
        %> @param param.rollOff                       The Roll-Off factor. You should define this value if you are using 'rc' or 'rrc' shapings. Usually, this number varies from 0 to 1.  if all channels have equal setup
        %>
        %> SimpleAWG_v1 - DAC_v1
        %> @param param.bitResolution                 Resolution of DAC in bits [Default: 8]
        %> @param param.targetENoB                    Target Effective Number of Bits
        %> @param param.resamplingRate                Resampling rate [see ResampleSkewJitter_v1]
        %> @param param.outputSamplingRate            The desired output sampling rate. [see ResampleSkewJitter_v1]
        %> @param param.skew                          Skew [see ResampleSkewJitter_v1]
        %> @param param.jitterVariance                Jitter amplitude [see ResampleSkewJitter_v1]
        %> @param param.clockError                    Clock deviation [see ResampleSkewJitter_v1]
        %> @param param.rectangularBandwidth          Bandwidth of rectangular filter [see ElectricalFilter_v1]
        %> @param param.gaussianOrder                 Order of Gaussian filter [see ElectricalFilter_v1]
        %> @param param.gaussianBandwidth             Bandwidth of Gaussian filter [see ElectricalFilter_v1]
        %> @param param.besselOrder                   Order of Bessel filter [see ElectricalFilter_v1]
        %> @param param.besselBandwidth               Bandwidth of bessel filter [see ElectricalFilter_v1]
        %>
        %> IQ_v1
        %> @param param.Vamp                          ??? [see IQ_v1]
        %> @param param.Vb                            ??? [see IQ_v1]
        %> @param param.Vpi                           ??? [see IQ_v1]
        %> @param param.IQphase_x                     ??? [see IQ_v1]
        %> @param param.IQphase_y                     ??? [see IQ_v1]
        %> @param param.IQgain_imbalance_x            ??? [see IQ_v1]
        %> @param param.IQgain_imbalance_y            ??? [see IQ_v1]
        %> @param param.f_off                         ??? [see IQ_v1]
        %>
        %> Laser_v1
        %> @param param.Fs                            Sampling frequency [Hz] [see Laser_v1]
        %> @param param.Rs                            Symbol rate [Hz] [see Laser_v1]
        %> @param param.Lnoise                        Signal length [Samples] [see Laser_v1]
        %> @param param.Fc                            Carrier frequency [Hz] [see Laser_v1]
        %> @param param.Power                         Output power [see Laser_v1]
        %> @param param.Laser_L                       FM noise PSD length [see Laser_v1 as L]
        %> @param param.Lir                           FM noise PSD length [see Laser_v1]
        %> @param param.linewidth                     Lorentzian linewidth [see Laser_v1]
        %> @param param.LFLW1GHZ                      Linewidth at 1GHz [see Laser_v1]
        %> @param param.HFLW                          High-frequency linewidth [see Laser_v1]
        %> @param param.fr                            Relaxation resonance frequency [see Laser_v1]
        %> @param param.K                             Damping factor [see Laser_v1]
        %>
        %> @retval obj      An instance of the class SimpleWDMTransmitter_v1
        function obj = SimpleWDMTransmitter_v1(varargin)
            if nargin % This will avoid this constructor if called from subclass
                param_cell=obj.init(varargin{1});
                %% Create objects
                CoherentTxCell = cell(1,obj.nChannels);
                for ii=1:obj.nChannels
                    CoherentTxCell{ii} = SimpleCoherentTransmitter_v1(param_cell{ii});
                end
                if strcmpi(obj.output,'comb') || strcmpi(obj.output,'both')
                    chCombiner_param = struct('nInputs',obj.nChannels);
                    chCombiner = ChannelCombiner_v1(chCombiner_param);
                end
                if strcmpi(obj.output,'both')
                    branches = cell(1,obj.nChannels);
                    for ii=1:obj.nChannels
                        branches{ii} = BranchSignal_v1(2);
                    end
                end
                
                %% Connect objects
                if strcmpi(obj.output,'both')
                    for ii=1:obj.nChannels
                        CoherentTxCell{ii}.connectOutput(branches{ii},1,1);
                        branches{ii}.connectOutput(chCombiner,1,ii);
                        branches{ii}.connectOutput(obj.outputBuffer,2,ii+1);
                    end
                    chCombiner.connectOutput(obj.outputBuffer,1,1);
                elseif strcmpi(obj.output,'comb')
                    for ii=1:obj.nChannels
                        CoherentTxCell{ii}.connectOutputs({chCombiner},ii);
                    end
                    chCombiner.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
                elseif strcmpi(obj.output,'concat')
                    for ii=1:obj.nChannels
                        CoherentTxCell{ii}.connectOutput(obj.outputBuffer,ii,ii);
                    end
                end
                
                %% Module export
                if strcmpi(obj.output,'both')
                    obj.exportModule(CoherentTxCell{:},branches{:},chCombiner);
                elseif strcmpi(obj.output,'comb')
                    obj.exportModule(CoherentTxCell{:},chCombiner);
                elseif strcmpi(obj.output,'concat')
                    obj.exportModule(CoherentTxCell{:});
                end                    
            end
        end
        function param_cell=init(obj,param)
            if ~isfield(param,'Laser_L') % Due to double naming of L in Laser_v1 and L in PatternGenerator_v1
               param.Laser_L=1; 
            end
            if isfield(param,'output')
               obj.output=param.output; 
            end
            
            props=setdiff(properties([obj.flag 'WDMTransmitter_v1']),properties('unit'));
            props=setdiff(props, properties('module'));
            props=setdiff(props, {'output'});
            try
                for nn=1:length(props)
                   eval(['obj.' props{nn} ' = param.' props{nn} ';']) ;
                end
            catch
               robolog('An unexpected error occured, please create a github issue with your code producing this error.','ERR')
            end
            if isfield(param, 'flag')
               obj.flag =  param.flag;
            end
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end
            if strcmpi(obj.output,'both') && obj.nOutputs~=obj.nChannels+1
                robolog('For the ''both'' output option, the number of outputs has to be nChannels+1.','ERR')
            end
            if obj.nChannels~=length(obj.lambda)
                robolog('The number of channels has to be the same as the number of wavelengths.','ERR')
            end
                % each channel different parameters
                param_cell = cell(1,obj.nChannels);
                if issorted(obj.lambda)
                    sortPattern=1:obj.nChannels;
                else
                    sortPattern=minIdx(bsxfun(@(x,y)abs(y-x),sort(obj.lambda),obj.lambda'),2);
                end
                for ii=1:obj.nChannels
                   param_cell{sortPattern(ii)} = paramDeepCopy([obj.flag 'CoherentTransmitter_v1'],param);
                   param_cell{sortPattern(ii)}.Laser_L           =   varOrCell(obj.Laser_L,ii);
                   param_cell{sortPattern(ii)}.linewidth         =   varOrCell(obj.linewidth,ii);
                   param_cell{sortPattern(ii)}.Power             =   varOrCell(obj.Power,ii);
                   param_cell{sortPattern(ii)}.modulationFormat  =   varOrCell(obj.modulationFormat,ii);
                   param_cell{sortPattern(ii)}.M                 =   varOrCell(obj.M,ii);
                   param_cell{sortPattern(ii)}.pulseShape        =   varOrCell(obj.pulseShape,ii);
                   param_cell{sortPattern(ii)}.rollOff           =   varOrCell(obj.rollOff,ii);
                   param_cell{sortPattern(ii)}.Fc                =   const.c/(obj.lambda(ii)*1e-9);
                end
        end
    end
end
