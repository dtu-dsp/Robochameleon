%> @file ExtendedWDMTransmitter_v1.m
%> @brief Extended WDM transmitter class implementation.

%>@class ExtendedWDMTransmitter_v1
%>@brief Extended WDM transmitter
%>
%> This is a simple WDM transmitter which contains nChannels simple coherent transmitters.
%> __Example__
%> 
%> @code
%> %General WDM channel
%> %see setupts/UnitsTesting/run_TestExtendedWDMTransmitter.m
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
%> Tx1 = ExtendedWDMTransmitter_v1(param);
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
classdef ExtendedWDMTransmitter_v1 < SimpleWDMTransmitter_v1
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type ExtendedWDMTransmitter_v1.
        %> It also constructs nChannels ExtendedCoherentTransmitter_v1.
        %>
        %> @param param.nChannels                     Number of WDM channels
        %> @param param.lambda                        Wavelengths of the every channel [nm] if this parameter is a cell array
        %> @param param.linewidth                     Laser linewidth of every channel if this parameter is a cell array
        %> @param param.modulationFormat              Modulation format of every channel if this parameter is a cell array
        %> @param param.M                             Modulation order of every channel if this parameter is a cell array
        %> @param param.pulseShape                    Pulseshape of every channel if this parameter is a cell array
        %> @param param.rollOff                       Roll-Off factor of every channel if this parameter is a cell array
        %>
        %> ExtendedAWG_v1 - WaveformGenerator_v1
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
        %> ExtendedAWG_v1 - DACPrecompensator_v1
        %> @param param.DACPreGaussianOrder           Order of Gaussian Pre-Filter [Default: 1]
        %> @param param.DACPreGaussianBandwidth       Bandwidth of Gaussian Pre-Filter
        %> @param param.DACPreBesselOrder             Order of Bessel Pre-Filter [Default: 1]
        %> @param param.DACPreBesselBandwidth         Bandwidth of Bessel Pre-Filter
        %>
        %> ExtendedAWG_v1 - DAC_v1
        %> @param param.bitResolution                 Resolution of DAC in bits [Default: 8]
        %> @param param.targetENoB                    Target Effective Number of Bits
        %> @param param.upsamplingRate                Upsampling rate [see DAC_v1]
        %> @param param.skew                          Skew [see DAC_v1]
        %> @param param.jitterVariance                Jitter amplitude [see DAC_v1]
        %> @param param.clockError                    Clock deviation [see DAC_v1]
        %> @param param.rectangularBandwidth          Bandwidth of rectangular filter
        %> @param param.DACGaussianOrder              Order of Gaussian filter [see DAC_v1]
        %> @param param.DACGaussianBandwidth          Bandwidth of Gaussian filter
        %> @param param.DACBesselOrder                Order of Bessel filter [see DAC_v1]
        %> @param param.DACBesselBandwidth            Bandwidth of bessel filter
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
        %> Laser_v3
        %> @param param.Fs                            Sampling frequency [Hz] [see Laser_v3]
        %> @param param.Rs                            Symbol rate [Hz] [see Laser_v3]
        %> @param param.Lnoise                        Signal length [Samples] [see Laser_v3]
        %> @param param.Fc                            Carrier frequency [Hz] [see Laser_v3]
        %> @param param.Power                         Output power [see Laser_v3]
        %> @param param.Laser_L                       FM noise PSD length [see Laser_v3 as L]
        %> @param param.Lir                           FM noise PSD length [see Laser_v3]
        %> @param param.linewidth                     Lorentzian linewidth [see Laser_v3]
        %> @param param.LFLW1GHZ                      Linewidth at 1GHz [see Laser_v3]
        %> @param param.HFLW                          High-frequency linewidth [see Laser_v3]
        %> @param param.fr                            Relaxation resonance frequency [see Laser_v3]
        %> @param param.K                             Damping factor [see Laser_v3]
        %>
        %> @retval obj      An instance of the class ExtendedWDMTransmitter_v1
        function obj = ExtendedWDMTransmitter_v1(param)
            param.flag='Extended';            
            param_cell=obj.init(param);% Called from SimpleWDMTransmitter_v1
            CoherentTxCell = cell(1,obj.nChannels);
            for ii=1:obj.nChannels
                CoherentTxCell{ii} = ExtendedCoherentTransmitter_v1(param_cell{ii});
            end
            chCombiner_param = struct('nInputs',obj.nChannels);
            chCombiner = ChannelCombiner_v1(chCombiner_param);
            
            % Connect
            for ii=1:obj.nChannels
                CoherentTxCell{ii}.connectOutputs({chCombiner},ii);
            end
            chCombiner.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            obj.exportModule(CoherentTxCell{:},chCombiner);
        end
    end
end
