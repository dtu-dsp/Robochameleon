%> @file QAM16Tx_v1.m
%> @brief QAM16 transmitter model
%> 
%> @class QAM16Tx_v1
%> @brief  QAM16 transmitter model
%>
%> 16-QAM generation via delay and add.
%>
%> @author Miguel Iglesias
classdef QAM16Tx_v1 < module
    
    properties
        nInputs = 0;
        nOutputs = 1;
        param;
    end
    
    methods
        function obj = QAM16Tx_v1(param)
            
            % Units
            pam4 = PAM4Tx_v1(param);
            splitter = BranchSignal_v1(2);
            Negator = Negator_v1;
            delay = Delay_v1(param.delayQAM, 'symbol');
            iq = IQIdeal_v1;
            
            % Connections
            pam4.connectOutput(splitter,1,1);
            splitter.connectOutputs({delay, Negator}, [1 1]);
            delay.connectOutput(iq,1,1);
            Negator.connectOutput(iq,1,2);
            iq.connectOutputs(obj.outputBuffer,1);
            
            % Save units
            obj.exportModule();
        end
    end
    
end

