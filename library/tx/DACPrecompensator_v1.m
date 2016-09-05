%> @file DACPrecompensator_v1.m
%> @brief Digital to analog conversion precompensator class implementation

%>@class DACPrecompensator_v1
%>@brief Digital to analog conversion precompensator
%>
%> 
%> \image html "DACPrecompensator_v1_blockdiagram.png"
%>
%> This is a digital to analog conversion precompensator which contains a digital
%> pre-filter and a quantizer.
%>
%> @author Rasmus Jones
%>
%> @version 1
classdef DACPrecompensator_v1 < module

    properties        
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;        
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type DACPrecompensator_v1.
        %> It also constructs a DigitalPreFilter_v1 and a Quantizer_v1
        %>
        %> @param param.nOutputs            Number of outputs
        %>
        %> DigitalPreFilter_v1
        %> @param param.gaussianOrder           Order of Gaussian Pre-Filter [Default: 1]
        %> @param param.gaussianBandwidth       Bandwidth of Gaussian Pre-Filter
        %> @param param.besselOrder             Order of Bessel Pre-Filter [Default: 1]
        %> @param param.besselBandwidth         Bandwidth of Bessel Pre-Filter
        %>
        %> @retval obj      An instance of the class DACPrecompensator_v1
        function obj = DACPrecompensator_v1(param)
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end
            
            dpf_param = paramDeepCopy('DigitalPreFilter_v1',param);
            %quant_param = paramDeepCopy('Quantizer_v1',param);
            
            dpf = DigitalPreFilter_v1(dpf_param);
            %quant = Quantizer_v1(quant_param);
            
            % Connect
            obj.connectInputs({dpf}, 1);
            dpf.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %quant.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            exportModule(obj);
        end
    end
end
