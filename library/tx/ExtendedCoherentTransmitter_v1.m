%> @file ExtendedCoherentTransmitter_v1.m
%> @brief Extended coherent transmitter class implementation.

%>@class ExtendedCoherentTransmitter_v1
%>@brief Extended coherent transmitter
%> 
%> This is a extended coherent transmitter which contains a
%> extended arbitrary waveform generator, a laser and an IQ modulator.
%>
%> Block diagram illustrating dependencies:
%>
%> \image html "ExtendedTx_v1_blockdiagram.png"
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef ExtendedCoherentTransmitter_v1 < SimpleCoherentTransmitter_v1
    
    methods

        %> @brief Class constructor
        %>
        %> Constructs an object of type ExtendedCoherentTransmitter_v1.
        %> It also constructs a ExtendedAWG_v1, Laser_v1 and IQModulator_v1.
        %>        
        %> @param param.nOutputs                      Number of outputs
        %>
        %> ExtendedAWG_v1 - WaveformGenerator_v1
        %> @param param.totalLength                   Output sequence length [symbols].
        %> @param param.typePattern                   Type of Pattern. Can be 'PRBS' or 'Random'.
        %> @param param.PRBSOrder                     Polynomial order (any integer 2-23; 27, 31)
        %> @param param.modulationFormat              Modulation format
        %> @param param.modulationOrder               Modulation order
        %> @param param.nModes                        Number of Modes (or polarizations)
        %> @param param.samplesPerSymbol              It is the desired output number of samples per symbol.
        %> @param param.symbolRate                    You are able to define a symbol rate for your signal here. The output sample frequency will be define as symbolRate*samplesPerSymbol.
        %> @param param.pulseShape                    Choose among 'rc', 'rrc', 'rz33%', 'rz50%', 'rz67%', 'nrz' or 'custom'; 
        %> @param param.filterCoeffs                  You should define this as a vector if you chose 'custom' 'pulseShape'.
        %> @param param.filterSymbolLength            You should define a symbol length for 'rc' or 'rrc' filters. The default value is 202.
        %> @param param.rollOff                       The Roll-Off factor. You should define this value if you are using 'rc' or 'rrc' shapings. Usually, this number varies from 0 to 1.
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
        %> Laser_v1
        %> @param param.Fs                            Sampling frequency [Hz] [see Laser_v1]
        %> @param param.Rs                            Symbol rate [Hz] [see Laser_v1]
        %> @param param.Lnoise                        Signal length [Samples] [see Laser_v1]
        %> @param param.Fc                            Carrier frequency [Hz] [see Laser_v1]
        %> @param param.Power                         Output power [see Laser_v1]
        %> @param param.L                             FM noise PSD length [see Laser_v1]
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
        function obj = ExtendedCoherentTransmitter_v1(param)
            param.flag='Extended';
            param = obj.init(param);
            AWG     = ExtendedAWG_v1(param.param_awg);
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
end
