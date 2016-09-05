%> @file SimpleCoherentTransmitter_v1.m
%> @brief Simple coherent transmitter class implementation.

%>@class SimpleCoherentTransmitter_v1
%>@brief Simple coherent transmitter
%> 
%> This is a simple coherent transmitter which contains a
%> simple arbitrary waveform generator, a laser and an IQ modulator.
%>
%> Block diagram illustrating dependencies:
%>
%> \image html "SimpleTx_v1_blockdiagram.png"
%>
%>
%> 
%> @author Rasmus Jones
%>
%> @version 1
classdef SimpleCoherentTransmitter_v1 < module

    properties        
        %> Number of inputs
        nInputs = 0;
        %> Number of outputs
        nOutputs = 1;        
    end
    
	properties(Access=protected)
       flag = 'Simple';
    end
    
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type SimpleCoherentTransmitter_v1.
        %> It also constructs a SimpleAWG_v1, Laser_v1 and IQ_v1.
        %>        
        %> @param param.nOutputs            Number of outputs
        %>
        %> SimpleAWG_v1 - WaveformGenerator_v1
        %> @param param.L                             Output sequence length [symbols].
        %> @param param.typePattern                   Type of Pattern. Can be 'PRBS' or 'Random'.
        %> @param param.PRBSOrder                     Polynomial order (any integer 2-23; 27, 31)
        %> @param param.modulationFormat              Modulation format
        %> @param param.M                             Modulation order
        %> @param param.N                             Number of Modes (or polarizations)
        %> @param param.samplesPerSymbol              It is the desired output number of samples per symbol.
        %> @param param.symbolRate                    You are able to define a symbol rate for your signal here. The output sample frequency will be define as symbolRate*samplesPerSymbol.
        %> @param param.pulseShape                    Choose among 'rc', 'rrc', 'rz33%', 'rz50%', 'rz67%', 'nrz' or 'custom'; 
        %> @param param.filterCoeffs                  You should define this as a vector if you chose 'custom' 'pulseShape'.
        %> @param param.filterSymbolLength            You should define a symbol length for 'rc' or 'rrc' filters. The default value is 202.
        %> @param param.rollOff                       The Roll-Off factor. You should define this value if you are using 'rc' or 'rrc' shapings. Usually, this number varies from 0 to 1.
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
        %> IQModulator_v1
        %> @param param.Vb                            Bias voltage [V]  [see IQModulator_v1]
        %> @param param.Vpi                           V pi for child modulators [V] [see IQModulator_v1]
        %> @param param.IQphase                       IQ phase angle [rad] [see IQModulator_v1]
        %> @param param.IQGainImbalance               Gain imbalance in I and Q [dB] [see IQModulator_v1]
        %> @param param.rescaleVdrive                 Force drive signal to a certain value [boolean] [see IQModulator_v1]
        %> @param param.Vamp                          What drive voltage should be forced to, if rescaling is enabled [V] [see IQModulator_v1]
        %>        
        %> @retval obj      An instance of the class SimpleCoherentTransmitter_v1
        function obj = SimpleCoherentTransmitter_v1(varargin)
            if nargin % This will avoid this constructor if called from subclass
                param = obj.init(varargin{1});
                AWG    = SimpleAWG_v1(param.param_awg);
                CopySignalParameters = BranchSignal_v1(2);
                laser   = Laser_v1(param.param_laser);
                iq      = IQModulator_v1(param.param_iq);            
                % Connect
                AWG.connectOutputs({CopySignalParameters},1);
                CopySignalParameters.connectOutputs({iq, laser}, [1 1]);
                laser.connectOutputs({iq},2);
                iq.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
                %% Module export
                exportModule(obj);
            end
        end
        function param = init(obj,param)
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end
            
            param.param_awg   = paramDeepCopy([obj.flag 'AWG_v1'],param);
            param.param_iq    = paramDeepCopy('IQModulator_v1',param);
            param.param_laser = paramDeepCopy('Laser_v1',param);
            
            param.param_laser.nInputs        = 1;
            param.param_iq.nInputs           = 2;
            param.param_iq.mode              = 'single';
        end
    end
end
