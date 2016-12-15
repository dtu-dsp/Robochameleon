%> @file VITERBI_CPR_v1
%> @brief contains implementation of Feed Forward Non-Decision-Aided CPR 
%>
%> @class VITERBI_CPR_v1
%> @brief Viterbi & Viterbi NDA carrier phase estimation.
%> 
%> @ingroup Metro Access & Short Range Communications
%> 
%> This class implements a non-decision-aided (NDA) feedforward carrier 
%> phase estimation (CPA) algorithm. The carrier recovery is based on the 
%> implementation of the Viterbi & Viterbi algorithm followed by 
%> differential demodulation as discussed in references [1,2]. 
%> Reference [3] is the seminal paper where the algorithm was 
%> first proposed.
%> 
%> The main idea is to detect the uncompensated phase ($\theta_0$) 
%> of a signal of the form
%> z_n = \left[ a_n \exp{(j\theta_0)} +m_n \right].
%> 
%> Where the original symbols are $a_n$ and the term $m_n$ is noise.
%> When the modulation format is QPSK the data symbols belong to the set:
%> 
%> $\{ exp(j2\pi m/M) | m=0,1,...,M-1\}$
%> 
%> The data dependency in $z_n$ is eliminated by taking the detected signal 
%> to the Mth power and then evaluating the argument. 
%> Phase estimation is done for blocks of the signal of size N_{vv} under 
%> the assumpition that the phase change is slow. 
%> Short block sizes give a more accurate representation of phase noise 
%> variation and large block sizes give a better compensation of amplitude 
%> noise.
%>
%> After exponentiation an M-fold ambiguity occurs on the phase.
%> There are M different values of m that satisfy 
%>  $\exp{(\hat{\theta}+2\pi m /M)M} =  \exp{(\hat{\theta})M} $
%> Diferential precoding is generally used to adresses the correction of 
%> the ambiguity, and both decoding and phase unwrapping are implemented 
%> here.
%> 
%> The phase that is stored has been unwrapped using the algorithm
%> described in [4] p56 eq.3.52.
%>
%> Example:
%> @code
%>      Pending
%> @endcode
%> 
%> "plot" function plots demodulated phase
%>
%> References: 
%> [1] Ly-Gagnon, D. S., Tsukamoto, S., Katoh, K., & Kikuchi, K. (2006). 
%>     "Coherent detection of optical quadrature phase-shift keying signals 
%>     with carrier phase estimation."
%>     Journal of Lightwave Technology, 24(1), 12.
%> [2] Goldfarb, G., & Li, G. (2006). 
%>     "BER estimation of QPSK homodyne detection with carrier phase 
%>      estimation using digital signal processing."
%>     Optics express, 14(18), 8043-8053.
%> [3] Viterbi, A. (1983). 
%>     "Nonlinear estimation of PSK-modulated carrier phase with 
%>      application to burst digital transmission." 
%>      IEEE Transactions on Information theory, 29(4), 543-551.
%> [4] J. C. M. Diniz and A. C. Bordonalli, “Estimador de desvio de 
%>     frequência para receptores ópticos coerentes digitais,” Dissertação 
%>     de Mestrado, 2013.
%>
%> @author Santiago Echeverri 

classdef VITERBI_CPR_v1 < unit
    
    properties
        nInputs = 1;
        nOutputs = 1;
        
        %> Main control parameters: N
        %> Number of precursors and post cursors used for the averaging
        %> window.
        N = 11;
        %> Highest integer number of blocks of size N by which the signal 
        %> can be divided. 
        n_blcks;
        %> Saved phase for x polarization
        phase_x;
        %> Saved phase for y polarization
        % phase_y; %Not used for now
        %Baud rate (for plotting, taken from input signal)
        Fb;   
        %> Other
        param;
        %> Frequency offset estimated from the ramp after unwrapping of
        %> phase
        f_off = 0;
    end
    
    methods
        %> @brief Class constructor
        %> 
        %> Class constructor - params are saved and checked
        %>
        %> @param param structure with loop parameters
        %>
        %> @retval obj instance of DDPLL_v1 class
        function obj = VITERBI_CPR_v1(param)
            if isfield(param,'N')
                obj.N = param.N;
            end
            if isfield(param,'draw')
                obj.draw = param.draw;
            end
        end
        
        %> @brief Travese function
        %> 
        %> Parses input, calls carrier recovery, parses output
        %>
        %> @param varargin input signal (either 1 for (I+jQ) or 2 for
        %>        (I,Q)). Dual polarization not yet supported
        %>
        %> @retval out signal with phase correction applied
        function out = traverse(obj, varargin)
            switch numel(varargin)
                case 1
                    sig1 = varargin{1};
                    if isreal(sig1.getNormalized)
                        error('Input signal components must be complex valued')
                    else
                        sig = sig1;
                    end
                case 2
                    sig1 = varargin{1};
                    sig2 = varargin{2};
                    sigmat = [sig1.getNormalized sig2.getNormalized];
                    if isreal(sigmat(:,1)) && isreal(sigmat(:,2))
                        sig = sig1.set(complex(sigmat(:,1),sigmat(:,2)));
                    else
                        error('When using 2 inputs, they must all be real valued')
                    end
            end
            
            [out] = obj.viterbi(sig);
            if obj.draw
                obj.plot();
            end
        end
        
        %> @brief Main PLL
        %>
        %> Performs carrier recovery
        %>
        %> @param Ein input signal 
        %>
        %> @retval Eout signal with phase correction applied
        function [Eout] = viterbi(obj, Ein)
            %% Initialization
            obj.Fb = Ein.Rs; Fs = Ein.Fs;
            obj.param.Ts = 1/Ein.Rs;
            
            sig = Ein.getRaw;
            
            L = int32(Ein.L);
            obj.N = int32(obj.N);
            obj.n_blcks = idivide(L,2*obj.N+1,'floor'); %Number of full sized blocks
                       
            % Center elements of each block of size 2*N+1.
            blck_indx_vec =  (1:obj.n_blcks)*(2*obj.N+1)-obj.N; 
            %% Phase extraction and slicing
            theta = zeros(1,obj.n_blcks);
            T = angle(sig);
            blck_indx = 1;
            for blck_cntr = blck_indx_vec 
                blck = (blck_cntr-obj.N):(blck_cntr+obj.N);
                % Phase extraction using the 4th power method
                theta(blck_indx) = (1/4)*angle(-sum(sig(blck).^4));
                % Implementation of the phase treshold operator T
                T(blck) = round(((T(blck) - theta(blck_indx))-pi/4)/(pi/2));
                blck_indx = blck_indx+1;
            end
            
            %% Differential decoding 
            d = T; 
            blck_indx = 1;
            for blck_cntr = blck_indx_vec 
                blck     = (blck_cntr-obj.N):(blck_cntr+obj.N-1);
                blck_p_1 = (blck_cntr-(obj.N-1)):(blck_cntr+obj.N);  %shifted index
                d(blck) = mod(T(blck_p_1)-T(blck),4);
                A = @(x)(abs(x)>abs(pi/4))*sign(x);
                
                % d is the decoded signal.
                %   d_{Nb}      =       T_1_Pu2                -       T_Nb_Pu1      + A(\phi_est_Pu2               -  \phi_est_Pu1) |_mod4   
                if ~isequal(blck_indx,obj.n_blcks)
                    d(blck_cntr+obj.N) = mod(T(blck_indx_vec(blck_indx+1)-obj.N)-T(blck_cntr+obj.N)+A(theta(blck_indx+1)-theta(blck_indx)),4);
                else
                    if isequal(mod(L,2*obj.N+1),0)
                        d(blck_cntr+obj.N) = mod(T(blck_cntr+obj.N),4);
                    else
                        % Case for when the last block is not a full sized block
                        
                        N_special = mod(L,2*obj.N+1);% This is the size of the last block            
                        last_blk = (L-N_special+1):L;
                        theta_last_blk = (1/4)*angle(-sum(sig(last_blk).^4));
                        T(last_blk) = round(((T(last_blk) - theta_last_blk)-pi/4)/(pi/2));   
                        
                        d(blck_cntr+obj.N) = mod(T(last_blk(1))-T(blck_cntr+obj.N)+A(theta_last_blk-theta(blck_indx)),4);
                        
                        d(last_blk) = mod(T((L-N_special):(L-1))-T((L-(N_special-1)):L),4);
                    end
                end
                blck_indx = blck_indx+1;
            end
            

            obj.phase_x = theta;
            
            Eout = signal_interface(d(1:end-1), struct('Rs', obj.Fb, 'Fs', Fs, 'P', Ein.P, 'Fc', Ein.Fc));
            
            
        end
        
        %> @brief Plot results
        %>
        %> Plots phase as a function of time, estimates frequency offset
        function plot(obj)
            figure(2833);
            L = obj.n_blcks;
            plot(0:L-1,obj.phase_x);
            set(gcf,'name','Wrapped phase noise')
            L_est = min(1e4,numel(obj.phase_x));
            est_f_off = (obj.phase_x(end)-obj.phase_x(end-L_est+1))/(2*pi*L_est)*obj.Fb;
            fprintf('Estimated frequency offset %0.0f MHz\n',est_f_off/1e6);    
            obj.f_off=est_f_off/1e6;
            %% Phase unwrap
            for ii = 2:length(obj.phase_x)
                obj.phase_x(ii) = obj.phase_x(ii)+floor(0.5+(obj.phase_x(ii-1)-obj.phase_x(ii))/(2*pi/4))*2*pi/4;
            end
            figure(2834);
            plot(0:L-1,obj.phase_x);
            set(gcf,'name','Unwrapped phase noise')
            
            
        end
        
    end
end