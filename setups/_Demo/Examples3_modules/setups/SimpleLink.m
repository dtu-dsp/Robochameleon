% This is a link with the simplest possible configuration.
%
% The link architecture is: PPG > SNR loading > BERT
classdef SimpleLink < module
    
    properties
        nInputs=0;
        nOutputs=0;
    end
    
    methods
        function obj = SimpleLink(param)
            
            %Unit constructors
            pg = PatternGenerator_v1(param.pg);
            ps = PulseShaper_v1(param.ps);
            snr = SNR_v1(param.SNR);
            bert = BERT_v1(param.bert);
            
            %connections
            pg.connectOutputs(ps, 1);
            ps.connectOutputs(snr, 1);
            snr.connectOutputs(bert,1);            
            
            %module construction
            obj.exportModule();
        end
    end
end

