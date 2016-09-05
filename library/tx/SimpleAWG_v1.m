%> @file SimpleAWG_v1.m
%> @brief Simple arbitrary waveform generator class implementation.

%>@class SimpleAWG_v1
%>@brief Simple arbitrary waveform generator.
%>
%> This is a simple arbitrary waveform generator which contains a
%> waveform generator and digital to analog converter.
%> 
%> Block diagram illustrating dependencies:
%>
%> \image html "SimpleAWG_v1_blockdiagram.png"
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef SimpleAWG_v1 < module

    properties        
        %> Number of inputs
        nInputs = 0;
        %> Number of outputs
        nOutputs = 1;        
    end 
    
    methods

        %> @brief Class constructor
        %>
        %> Constructs an object of type SimpleAWG_v1.
        %> It also constructs a WaveformGenerator_v1 and DAC_v1.
        %> 
        %>
        %> @param param.nOutputs            Number of outputs
        %>
        %> WaveformGenerator_v1
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
        %> DAC_v1
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
        %> @retval obj      An instance of the class SimpleAWG_v1
        function obj = SimpleAWG_v1(param)                                       
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end
            wg_param = paramDeepCopy('WaveformGenerator_v1',param);
            dac_param =  paramDeepCopy('DAC_v1',param);
            newFields = {'gaussianOrder', 'gaussianBandwidth','besselOrder','besselBandwidth'};
            oldDACFields = {'DACGaussianOrder', 'DACGaussianBandwidth','DACBesselOrder','DACBesselBandwidth'};
            for nn=1:length(newFields)
                if isfield(param, oldDACFields{nn})
                    eval(['dac_param.' newFields{nn} ' = param.' oldDACFields{nn} ';']);
                    dac_param=rmfield(dac_param, oldDACFields{nn});
                end
            end
            
            wg = WaveformGenerator_v1(wg_param);
            dac = DAC_v1(dac_param);
            % Connect
            wg.connectOutputs(repmat({dac},[1 wg.nOutputs]),1:wg.nOutputs);
            dac.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            exportModule(obj);
        end
    end
end
