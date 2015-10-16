%> @file SHF_DAC_v1.m
%> @brief implementation of an SHF Digital-analog converter module
%>
%> @class SHF_DAC_v1
%> @brief SHF Digital-analog converter module
%>
%> This models mapping of the 4 bit SHF DAC at 32 Gbaud:
%> https://www.shf.de/fileadmin/download/Communication/products/04_high_speed_modules/DAC/datasheet_shf_612_a_v002.pdf
%>
%> Note this is not a DAC in a "conventional" sense - it only does the mapping.  The input must be
%> a binary signal with 1 sample per symbol. Then you can use PulseShaper_v1 and SNR_v1 or OSNR_v1 for
%>  bandwidth and noise limitations respectively.
%>
%>  Ordering is LSB to MSB
%>
%> @author Miguel Iglesias Olmedo
%> @see PulseShaper_v1
classdef SHF_DAC_v1 < unit

    properties
        %>  Number of inputs
        nInputs;
	%>  Number of outputs
        nOutputs = 1;
    end
    
    methods
	%>  @brief Class constructor
        function obj = SHF_DAC_v1(nInputs)
            obj.nInputs = nInputs;
        end
	%>  @brief Main function
        function out = traverse(obj,varargin)
            sig = varargin{1};
%             Pref = sig.P;
            for i=2:obj.nInputs
%                 Pi = varargin{i}.P;
%                 Pi = pwr(Pi.SNR,{(2^(i-1))^2*Pref.P('W'), 'W'});
%                 sig = sig.plus(varargin{i}.set('P',Pi));
                 sig = sig.plus(varargin{i}.fun1(@(x) 2^(i-1)*x));
            end
            out = sig;
        end
    end
    
end

