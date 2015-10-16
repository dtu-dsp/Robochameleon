%> @file PAM4Tx_v1.m
%> @brief PAM4 transmitter model
%> 
%> @class PAM4Tx_v1
%> @brief  PAM4 transmitter model
%>
%> PAM4 generation via delay and add.
%>
%> @author Miguel Iglesias
classdef PAM4Tx_v1 < module
    
    properties
        nInputs = 0;
        nOutputs = 1;
        param;
    end
    
    methods
        function obj = PAM4Tx_v1(param)
            obj.param.ppg.order         = param.prbsSize;
            obj.param.ppg.total_length  = param.total_length;
            obj.param.ppg.Rs            = param.Rs;
            obj.param.ppg.levels        = [-1 1];
            obj.param.delayPAM          = param.delayPAM;
            
            % 4 PAM block
            ppg = PPG_v1(obj.param.ppg);
            splitter = BranchSignal_v1(2);
            Negator = Negator_v1;
            delay = Delay_v1(obj.param.delayPAM, 'bit');
            dac = SHF_DAC_v1(2);
            ppg.connectOutput(splitter,1,1);
            splitter.connectOutputs({delay, Negator}, [1 1]);
            Negator.connectOutput(dac,1,1);
            delay.connectOutput(dac,1,2);
            dac.connectOutputs(obj.outputBuffer,1);
            % Save units
            obj.exportModule();
        end
    end
    
end

