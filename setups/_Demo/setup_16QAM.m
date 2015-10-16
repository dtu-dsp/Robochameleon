% Back-to-back 16QAM setup
%
% The link architecture is: 16QAM transmitter > SNR loading > BERT and DSO
% Everything happens in the symbol domain - no analog effects are included
% (e.g. phase noise, coherent front end, ADC, ...)
%
classdef setup_16QAM < module
    
    properties
        nInputs = 0; % Number of input arguments
        nOutputs = 0; % Number of output arguments

        
    end
    
    methods
 
        function obj = setup_16QAM(param)
            % Constructors
            tx = QAM16Tx_v1(param.qam16);
            dso = DSO_v1;
            bert = BERT_v1(param.bert);
            splitter = BranchSignal_v1(2);
            snr = SNR_v1(param.SNR);
            
            % Connections
            tx.connectOutput(snr,1,1)
            snr.connectOutput(splitter,1,1);
            splitter.connectOutputs({dso, bert}, [1 1]);
                        
            % Module constructor
            obj.exportModule();
        end
    end
    
end

