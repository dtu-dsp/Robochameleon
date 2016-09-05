%> @file DAC_v1.m
%> @brief Digital to analog converter class implementation

%>@class DAC_v1
%>@brief Digital to analog converter
%>
%> 
%> This is a digital to analog converter which contains a upsampler
%> and an electrical filter.
%> 
%> Block diagram illustrating dependencies:
%>
%> \image html "DAC_v1_blockdiagram.png"
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef DAC_v1 < module
    properties        
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;        
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type DAC_v1.
        %> It also constructs a Quantizer_v1, a ResampleSkewJitter_v1, and a ElectricalFilter_v1
        %> 
        %> @param param.nOutputs            Number of outputs
        %>
        %> Quantizer_v1
        %> @param param.bitResolution           Resolution of DAC in bits [Default: 8]
        %> @param param.targetENoB              Target Effective Number of Bits
        %>
        %> ResampleSkewJitter_v1
        %> @param param.resamplingRate          Resampling rate [Default: 1] (It is a downsampling rate, for upsampling use 1/param.resamplingRate)
        %> @param param.outputSamplingRate      The desired output sampling rate.
        %> @param param.skew                    Skew [Default: 0]
        %> @param param.jitterVariance          Jitter amplitude [Default: 0]
        %> @param param.clockError              Clock deviation [Default: 0]
        %>
        %> ElectricalFilter_v1
        %> @param param.rectangularBandwidth    Bandwidth of rectangular filter
        %> @param param.gaussianOrder           Order of Gaussian filter [Default: 0]
        %> @param param.gaussianBandwidth       Bandwidth of Gaussian filter
        %> @param param.besselOrder             Order of Bessel filter [Default: 0]
        %> @param param.besselBandwidth         Bandwidth of bessel filter
        %> @param param.outputVoltage           Output Voltage [Default: 1]
        %> @param param.amplitudeImbalance      Amplitude Imbalance [Default: 1]
        %> @param param.levelDC                 DC level [Default: 0]
        %> 
        %> @retval obj      An instance of the class DACPrecompensator_v1
        function obj = DAC_v1(param)
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end          
            quant_param = paramDeepCopy('Quantizer_v1',param);
            usj_param = paramDeepCopy('ResampleSkewJitter_v1',param);
            ef_param = paramDeepCopy('ElectricalFilter_v1',param);
                        
            quant = Quantizer_v1(quant_param);
            usj = ResampleSkewJitter_v1(usj_param);
            ef = ElectricalFilter_v1(ef_param);
            
            % Connect
            obj.connectInputs({quant}, 1);
            quant.connectOutputs(repmat({usj},[1 quant.nOutputs]),1:quant.nOutputs)
            usj.connectOutputs(repmat({ef},[1 usj.nOutputs]),1:usj.nOutputs);
            ef.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            exportModule(obj);
        end
    end
end
