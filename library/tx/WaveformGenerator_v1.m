    %> @file WaveformGenerator_v1.m
%> @brief Waveform generator class implementation.

%>@class WaveformGenerator_v1
%>@brief Waveform generator.
%>
%> This is a waveform generator which contains a symbol generator and pulseshaper.
%>
%> Block diagram illustrating dependencies:
%>
%> \image html "WaveformGenerator_v1_blockdiagram.png"
%> 
%> __Example__
%> @code
%>      param.M                 = 4;
%>      param.modulationFormat  = 'QAM';
%>      param.samplesPerSymbol  = 16;
%>      param.pulseShape        = 'rrc';
%>      param.rollOff           = 0.2;
%>      wg      = WaveformGenerator_v1(param);
%>      sigOut  = wg.traverse();
%> @endcode
%>
%> @author Rasmus Jones
%>
%> @version 1
%>
%> @date February 2016
classdef WaveformGenerator_v1 < module
    
        properties
            %> Number of inputs
            nInputs = 0;
            %> Number of outputs
            nOutputs = 1;
        end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Constructs an object of type WaveformGenerator_v1.
        %> It also constructs a SymbolGenerator_v1 and a PulseShaper_v1
        %>
        %> @param param.nOutputs            Number of outputs
        %> @param param.M                   Modulation order
        %> @param param.L                   Output sequence length [symbols].
        %> @param param.PRBSOrder           Polynomial order (any integer 2-23; 27, 31)
        %> @param param.modulationFormat    Modulation format
        %> @param param.M                   Modulation order
        %> @param param.N                   Number of Modes (or polarizations)
        %> @param param.samplesPerSymbol    It is the desired output number of samples per symbol.
        %> @param param.symbolRate          You are able to define a symbol rate for your signal here. The output sample frequency will be define as symbolRate*samplesPerSymbol.
        %> @param param.pulseShape          Choose among 'rc', 'rrc', 'rz33%', 'rz50%', 'rz67%', 'nrz' or 'custom'; 
        %> @param param.filterCoeffs        You should define this as a vector if you chose 'custom' 'pulseShape'.
        %> @param param.filterSymbolLength  You should define a symbol length for 'rc' or 'rrc' filters. The default value is 202.
        %> @param param.rollOff             The Roll-Off factor. You should define this value if you are using 'rc' or 'rrc' shapings. Usually, this number varies from 0 to 1.
        %>
        %> @retval obj      An instance of the class WaveformGenerator_v1
        function obj = WaveformGenerator_v1(param)
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end

            sg_param = paramDeepCopy('SymbolGenerator_v1',param);
            ps_param = paramDeepCopy('PulseShaper_v1',param);
            
            sg = SymbolGenerator_v1(sg_param);
            ps = PulseShaper_v1(ps_param);
            % Connect
            sg.connectOutputs(repmat({ps},[1 sg.nOutputs]),1:sg.nOutputs);
            ps.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            exportModule(obj);
        end
    end
end