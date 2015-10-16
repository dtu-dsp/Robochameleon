% 16QAM setup with transmission over a nonlinear channel, with realistic
% impairments
%
% The link architecture is: 16QAM digital generation > upsampling > analog
% Tx model > linear bulk channel model > OSNR loading > analog Rx model >
% DSP chain
%
classdef setup_16QAMNonlinChannel < module
    
    properties
        nInputs = 0; % Number of input arguments
        nOutputs = 0; % Number of output arguments
        
    end
    
    methods
        function obj = setup_16QAMNonlinChannel(param)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Constructors
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % DATA GENERATION
            ppg = PPG_v1(param.ppg);
            dac = SHF_DAC_v1(param.ppg.nOutputs);
            Negator = Negator_v1;
            splitter1 = BranchSignal_v1(2);
            delay1 = Delay_v1(604);
            Combiner_v11 = Combiner_v1('complex',2);
            
            % X & Y SIGNAL GENERATION
            ps = PulseShaper_v1(param.ps);
            PolMux = PolMux_v1(600);
            
            % OPTICAL SIGNAL MODULATION
            laser = Laser_v1(param.laser);
            iq = IQ_v1(param.iq);
            
            % CHANNEL
            nlinch = NonlinearChannel_v1(param.nlinch);
            
            % RECEIVER
            cfe = CoherentFrontend_v1(param.coh);
            ADC = ADC_v1(param.ADC);
            Combiner_v12 = Combiner_v1('complex',4);
            
            cdcomp = CDCompensation_v1(param.cdcomp);
            resampler = Resample_v1(param.retiming);           
            decimator = Decimate_v1(param.decimator);    
            dsp = AdaptiveEqualizer_MMA_RDE_v1(param.dsp.eq);
            cpr = DDPLL_v1(param.dsp.crm);
            
            bert = BERT_v1(param.bert);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Connections
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % DATA GENERATION
            ppg.connectOutputs(repmat({dac},[1 param.ppg.nOutputs]),1:param.ppg.nOutputs);
            dac.connectOutputs(splitter1,1);
            splitter1.connectOutputs({Negator delay1},[1 1]);
            Negator.connectOutputs(Combiner_v11,1);
            delay1.connectOutputs(Combiner_v11,2);
            Combiner_v11.connectOutputs(PolMux,1);
            
            % POLMUX EMULATION AND TX MODEL
            PolMux.connectOutputs(ps,1);

            ps.connectOutput(iq,1,1);
            laser.connectOutput(iq,1,2);
            iq.connectOutput(nlinch,1,1);
            
            % CHANNEL
            nlinch.connectOutputs(cfe, 1);
            
            % RECEIVER
            cfe.connectOutputs({ADC,ADC,ADC,ADC},1:4);
            ADC.connectOutputs({Combiner_v12,Combiner_v12,Combiner_v12,Combiner_v12},1:4);
            Combiner_v12.connectOutput(cdcomp,1,1);
            
            cdcomp.connectOutputs(resampler,1);
            
            resampler.connectOutputs(decimator,1);
            
            decimator.connectOutputs(dsp,1);
            
            dsp.connectOutputs(cpr,1);
            
            cpr.connectOutputs(bert, 1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Module construction
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            exportModule(obj);
        end
        
    end
    
end

