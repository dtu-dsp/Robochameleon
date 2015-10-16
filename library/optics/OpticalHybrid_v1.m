%> @filt OpticalHybrid_v1.m
%> @brief Passive part of an optical hybrid
%>
%> @class OpticalHybrid_v1
%> @brief Passive part of an optical hybrid
%> 
%>  @ingroup physModels
%>
%> Simple 2x4 MMI model.  Converts input field to single from double due to
%> memory concerns.
%>
%> Signal inputs: 2
%>      -For conventional I-Q definitions, signal goes to input 1, LO to input 2
%> 
%> Signal outputs: 4
%>       -Outputs 1 and 2 are in-phase (I+ and I-, respectively)
%>       -Outputs 3 and 4 are quadrature (Q+ and Q-, respectively)
%>
%> @author Molly Piels
%> @version 1
classdef OpticalHybrid_v1 < unit

    
    properties
        
        %> Optical hybrid phase angle
        phase_angle = pi/2; 
        
        %> Number of input arguments
        nInputs = 2; 
        %> Number of output arguments
        nOutputs = 4; 
    end
    
    methods
        
        %>  @brief Class constructor
        %>
        %>  Class constructor
        %> 
        %> Example:
        %> @code
        %> hybrid = OpticalHybrid_v1(struct('phase_angle', pi/2));
        %> @endcode
        %>
        %> @param param.phase_angle hybrid phase angle
        function obj = OpticalHybrid_v1(params)
            setparams(obj,params);
        end
        
        %>  @brief Traverse function
        %>
        %>  Applies frequency shift to LO, then mixes LO with signal
        %> coherently
        %>
        %> @param sig input signal
        %> @param lo input local oscillator (swapping LO and signal swaps I and Q)
        %>
        %> @retval out1 I+
        %> @retval out2 I-
        %> @retval out3 Q+
        %> @retval out4 Q-
        %> @retval results no results
        function [out1,out2,out3,out4] = traverse(obj,sig,lo)
            phase = exp(1j*obj.phase_angle);
            
            %FIXME
            %MEMORY
            Elo = single(getScaled(lo));
            
            % LO setting
            df = lo.Fc-sig.Fc;
            Elo = Elo(1:sig.L,:); % Adjust LO signal length
            t = (1:sig.L)'/sig.Fs;
            Elo = bsxfun(@times,Elo,exp(2j*pi*df*t)); % Adjust LO frequency
            clear('t'); %MEMORY
            
            % Power, noise, and SNR tracking
            Psig = [sig.PCol];
            PLO = [lo.PCol];
            for jj=1:numel(Psig)
                P_out(jj) = Psig(jj)+PLO(jj);
            end

            
            % Generate outputs (power scaled by 4, a hybrid is a 1x4
            % splitter)
            out1 = set(sig,'E',(getScaled(sig)+Elo)/2,'PCol',P_out/4); % Reuse sig by re-setting field and power
            out2 = set(sig,'E',(getScaled(sig)-Elo)/2,'PCol',P_out/4);
            out3 = set(sig,'E',(getScaled(sig)-phase*Elo)/2,'PCol',P_out/4);
            out4 = set(sig,'E',(getScaled(sig)+phase*Elo)/2,'PCol',P_out/4);

            %             OLD CONVENTION
%             out1=signal_interface((Esig+Elo)/2,struct('Fs',sig.Fs,'Rs',sig.Rs, 'P', P_out, 'Fc', sig.Fc));
%             out2=signal_interface((Esig-Elo)/2,struct('Fs',sig.Fs,'Rs',sig.Rs, 'P', P_out, 'Fc', sig.Fc));
%             out3=signal_interface((Esig-phase*Elo)/2,struct('Fs',sig.Fs,'Rs',sig.Rs, 'P', P_out, 'Fc', sig.Fc));
%             out4=signal_interface((Esig+phase*Elo)/2,struct('Fs',sig.Fs,'Rs',sig.Rs, 'P', P_out, 'Fc', sig.Fc));            
        end
        
    end
    
end