%> @file ExtendedAWG_v1.m
%> @brief Extended arbitrary waveform generator class implementation.

%>@class ExtendedAWG_v1
%>@brief Extended arbitrary waveform generator.
%>
%> This is an extended arbitrary waveform generator which contains a
%> waveform generator, digital to analog conversion precompensator and digital to analog converter.
%>
%> Block diagram illustrating dependencies:
%>
%> \image html "ExtendedAWG_v1_blockdiagram.png"
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef ExtendedAWG_v1 < module

    properties        
        %> Number of inputs
        nInputs = 0;
        %> Number of outputs
        nOutputs = 1;        
    end

    methods

        %> @brief Class constructor
        %>
        %> Constructs an object of type ExtendedAWG_v1.
        %> It also constructs a WaveformGenerator_v1, a DACPrecompensator_v1 
        %> and DAC_v1.
        %>
        %> @param param.nOutputs            Number of outputs
        %>
        %> WaveformGenerator_v1
        %> @param param.totalLength                   Output sequence lenght [symbols].
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
        %> DACPrecompensator_v1
        %> @param param.DACPreGaussianOrder           Order of Gaussian Pre-Filter [Default: 1]
        %> @param param.DACPreGaussianBandwidth       Bandwidth of Gaussian Pre-Filter
        %> @param param.DACPreBesselOrder             Order of Bessel Pre-Filter [Default: 1]
        %> @param param.DACPreBesselBandwidth         Bandwidth of Bessel Pre-Filter
        %>
        %> DAC_v1
        %> @param param.bitResolution                 Resolution of DAC in bits [Default: 8]
        %> @param param.targetENoB                    Target Effective Number of Bits
        %> @param param.upsamplingRate          Upsampling rate [see DAC_v1]
        %> @param param.skew                    Skew [see DAC_v1]
        %> @param param.jitterVariance          Jitter amplitude [see DAC_v1]
        %> @param param.clockError              Clock deviation [see DAC_v1]
        %> @param param.rectangularBandwidth    Bandwidth of rectangular filter
        %> @param param.DACGaussianOrder        Order of Gaussian filter [see DAC_v1]
        %> @param param.DACGaussianBandwidth    Bandwidth of Gaussian filter
        %> @param param.DACBesselOrder          Order of Bessel filter [see DAC_v1]
        %> @param param.DACBesselBandwidth      Bandwidth of bessel filter
        %>
        %> @retval obj      An instance of the class ExtendedAWG_v1
        function obj = ExtendedAWG_v1(param)                                       
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end
            wg_param = paramDeepCopy('WaveformGenerator_v1',param);
            dacpre_param = paramDeepCopy('DACPrecompensator_v1',param);
            dac_param =  paramDeepCopy('DAC_v1',param);
            newFields = {'gaussianOrder', 'gaussianBandwidth','besselOrder','besselBandwidth'};
            oldDACPreFields = {'DACPreGaussianOrder', 'DACPreGaussianBandwidth','DACPreBesselOrder','DACPreBesselBandwidth'};
            oldDACFields = {'DACGaussianOrder', 'DACGaussianBandwidth','DACBesselOrder','DACBesselBandwidth'};
            for nn=1:length(newFields)
                if isfield(param, oldDACPreFields{nn})
                    eval(['dacpre_param.' newFields{nn} ' = param.' oldDACPreFields{nn} ';']);
                    dacpre_param=rmfield(dacpre_param, oldDACPreFields{nn});
                    dac_param=rmfield(dac_param, oldDACPreFields{nn});
                end
                if isfield(param, oldDACFields{nn})
                    eval(['dac_param.' newFields{nn} ' = param.' oldDACFields{nn} ';']);
                    dacpre_param=rmfield(dacpre_param, oldDACFields{nn});
                    dac_param=rmfield(dac_param, oldDACFields{nn});
                end
            end            
            
            wg = WaveformGenerator_v1(wg_param);
            dacpre = DACPrecompensator_v1(dacpre_param);
            dac = DAC_v1(dac_param);
            % Connect
            wg.connectOutputs(repmat({dacpre},[1 wg.nOutputs]),1:wg.nOutputs);
            dacpre.connectOutputs(repmat({dac},[1 dacpre.nOutputs]),1:dacpre.nOutputs);
            dac.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            exportModule(obj);
        end
    end
end
