% This is a link with the simplest possible configuration.  The script
% run_sweep_DemoSetup.m runs it
%
% The link architecture is: PPG > SNR loading > BERT
% One PPG output is attached to the BERT, and this binary sequence is used
% as the reference for error counting
classdef setup_DemoSetup < module
    
    properties
        nInputs=0;
        nOutputs=0;
        
        
    end
    
    methods
        function obj = setup_DemoSetup(param)
            obj.draw=true;
            
            %Unit constructors
            ppg = PPG_v1(param.ppg);
            snr = SNR_v1(param.SNR);
            bert = BERT_v1(param.bert);
            
            %connections
            ppg.connectOutputs({snr, bert},1:2);
            snr.connectOutputs(bert,1);            
            
            %module construction
            obj.exportModule();
        end
    end
end

