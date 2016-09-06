%> @file DDPLL_v1.m
%> @brief contains implementation of decision-directed PLL
%>
%> @class DDPLL_v1
%> @brief Second order type II decision-directed PLL
%>
%> @ingroup coreDSP
%>
%> This class implements a decision-directed PLL for frequency offset
%> correction and carrier phase recovery as described in \ref MeyerBook "[1, section 5.8]".  The loop filter is
%> proportional-integrator type and based on the implementation discussed
%> in \ref BestBook "[2, Software PLL chapter]".
%>
%> __Tuning the feedback parameters__
%>
%> tau1 and tau2 are as defined in standard continuous time PI-PLL theory -
%> i.e. the loop filter will be described by
%>
%> F(s) = (1+tau2*s)/(tau1*s)
%>
%> Kv is a discrete quantity.  The analogous continuous time loop gain is
%> given by
%>
%> Kv_cts = 2*Kv/Ts
%>
%> Translation from continuous to discrete is accomplished using the
%> bilinear Z transform, which is why tan(Ts/2*tau) appears in the script.
%> Then loop parameters are given by
%>
%> wn = loop BW in rad/s = sqrt(Kv_cts/tau1)
%>
%> damping_factor = wn*tau2/2
%>
%> __Example__
%> @code
%> param.ddpll.constellationType = '16-QAM';
%> ddpll = DDPLL_v1(param.ddpll);
%> @endcode
%>
%> __Advanced example__
%> @code
%> Rs = 28e9;       %baud rate
%> param.ddpll.Kv = 0.3;
%> PI_BW = 100e6;    %Hz
%> PI_damping = 5;
%> param.ddpll.tau1 = (2*param.ddpll.Kv*Rs)/((2*pi*PI_BW)^2);
%> param.ddpll.tau2 = PI_damping*2/(2*pi*PI_BW);
%> param.ddpll.speedupEnabled = 1;
%> param.ddpll.constellationType = 'QAM';
%> ddpll = DDPLL_v1(param.ddpll);
%> @endcode
%>
%> __Results:__
%> * phaseEstimates - Vectors containing the phases estimated by the DDPLL
%> * frequencyOffsets - Estimation of the frequency offset for each component
%> * linewidths - Estimation of the phase noise linewidth for each component. Highly approximate and will be
%>   affected by the SNR.
%>
%> __References:__
%>
%> \anchor MeyerBook [1] H. Meyer, Digital Communication Receivers: Synchronization, Channel estimation, and Signal Processing
%> Wiley 1998. Section 5.8 and 5.9.
%>
%> \anchor BestBook [2] R. Best, Phase-Locked Loops: Design, Simulation, & Applications,
%> McGraw-Hill 1997. Chapter: Software PLL
%>
%> @author Molly Piels (copied from earlier Robochameleon)
%> @author Simone Gaiarin
%>
%> @see constref.m
classdef DDPLL_v1 < unit
    
    properties
        %> Type of constellation (PSK, QAM, ...)
        refConstellation;
        %> Loop constant
        Kv = 0.3;
        %> PI paramters 1
        tau1 = 1/(2*pi*10e6);
        %> PI paramters 1
        tau2 = 1/(2*pi*10e6);
        %> Initial phase of the PLL
        initialPhase = 0;
        %> Flag to process a single polarization and apply the results to all the others
        speedupEnabled = 0;
        %Baud rate (for plotting, taken from input signal)
        Rs;
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> @param param.constellationType Type of constellation to be used in the decision directed phase
        %>                                detector. Possible values: {'PSK', 'QAM', ...} or using the fast syntax {'QPSK', '16-QAM', ...}.
        %>                                See constref.m for all the possible values.
        %> @param param.M Number of symbols in the constellation. Optional if fast syntax is used to define
        %>                the constellation type.
        %> @param param.Kv Loop constant. Can be a scalar or a vector if different values should be used
        %>                 for the different input components (modes). Default: 0.3.
        %> @param param.tau1 PI filter parameter 1. Default:1/(2*pi*PI_BANDWIDTH) with PI_BANDWIDTH = 10e6
        %> @param param.tau2 PI filter parameter 2. Default:1/(2*pi*PI_BANDWIDTH) with PI_BANDWIDTH = 10e6
        %> @param param.initialPhase Phse used to initialize the DDPLL. Default: 0
        %> @param param.speedupEnabled If true the phase is estimated for a single component and used to
        %>                             compensate all the other components. Default: False.
        %>
        %> @retval obj instance of DDPLL_v1 class
        function obj = DDPLL_v1(param)
            % Generate and normalize an ideal constellation for the decision directed Phase Error Detector
            if isfield(param, 'M')
                [refConstellation, P] = constref(param.constellationType, param.M);
                param = rmfield(param, {'constellationType', 'M'});
            else
                [refConstellation, P] = constref(param.constellationType);
                param = rmfield(param, 'constellationType');
            end
            obj.refConstellation = refConstellation/sqrt(P);
            REQUIRED_PARAMS = {};
            QUIET_PARAMS = {'Rs', 'refConstellation'};
            obj.setparams(param, REQUIRED_PARAMS, QUIET_PARAMS);
        end
        
        %> @brief Travese function
        %>
        %> Run the pll on the input signal to estimate the phase and then applies the correction to the input
        %> signal.
        %>
        %> Saves the phase estimates and the frequency offsets for each components in the results structure.
        %>
        %> @param varargin Case 1: signal_interface with N complex components (modes).
        %> @param varargin Case 2: 2 x signal_interface with 1 complex component.
        %> @param varargin Case 3: 4 x signal_interface with 4 real components.
        %>
        %> @retval out signal with phase correction applied
        function out = traverse(obj, varargin)
            switch numel(varargin)
                case 1
                    % General case. Can manage multi column input
                    sig = varargin{1};
                    Ein = sig.getNormalized;
                case 2
                    sig1 = varargin{1};
                    sig2 = varargin{2};
                    Ein = [sig1.getNormalized sig2.getNormalized];
                    if isreal(Ein(1,:)) || isreal(Ein(2,:))
                        error('Input signal components must be complex valued.')
                    else
                        sig = sig1.set(Ein(:,1:2));
                    end
                case 4
                    sig1 = varargin{1};
                    sig2 = varargin{2};
                    sig3 = varargin{3};
                    sig4 = varargin{4};
                    Ein = [sig1.getNormalized sig2.getNormalized sig3.getNormalized sig4.getNormalized];
                    if isreal(Ein(:,1)) && isreal(Ein(:,2)) ...
                            && isreal(Ein(:,3)) && isreal(Ein(:,4))
                        sig = sig1.set([complex(Ein(:,1),Ein(:,2))...
                            complex(Ein(:,3),Ein(:,4))]);
                    else
                        error('When using 4 inputs, they must all be real valued')
                    end
            end
            
            % Loop gain
            if isscalar(obj.Kv)
                obj.Kv = repmat(obj.Kv,[sig.N 1]);
            elseif isvector(obj.Kv) && numel(obj.Kv) == sig.N
                % Ok. We have a vector of Kv as long as the number of input columns
            else
                robolog(['Kv must be either a scalar or a vector with as many elements as the number of input components ' ...
                    '(%d in this specific case).'], 'ERR', sig.N);
            end
            
            robolog('Carrier recovery started.','NFO');
            Ts = 1/sig.Rs;
            if obj.speedupEnabled
                % Compute the phase for the first component only and then apply the same to all the other
                % components
                [~, phaseEstimate] = obj.pll(Ein(:,1), Ts, obj.Kv(1), obj.tau1, obj.tau2, ...
                    obj.refConstellation, obj.initialPhase, obj.N);
                % Save phase estimates in the results
                obj.results.phaseEstimates = repmat(phaseEstimate, 1);
                % Create a new signal_interface with the new field with the correct phase
                out = sig.fun1( @(x) x.*exp(-1i*phaseEstimate));
            else
                E_hat = zeros(sig.L, sig.N);
                for i=1:sig.N
                    [E_hat_singleComponent, phaseEstimate] = obj.pll(Ein(:,i), Ts, obj.Kv(i), obj.tau1, obj.tau2, ...
                        obj.refConstellation, obj.initialPhase);
                    E_hat(:, i) = E_hat_singleComponent;
                    % Save phase estimates in the results
                    obj.results.phaseEstimates(:, i) = phaseEstimate;
                end
                % Create a new signal_interface with the new field with the correct phase
                out = sig.set(E_hat);
            end
            robolog('Carrier recovery complete.','NFO');
            
            % Estimate frequency offset
            L_est = min(1e4, size(obj.results.phaseEstimates, 1)-1);
            frequencyOffset = (obj.results.phaseEstimates(end, :) ...
                - obj.results.phaseEstimates(end-L_est+1, :))/(2*pi*L_est)*sig.Rs;
            obj.results.frequencyOffsets = frequencyOffset;
            robolog('Estimated frequency offset (first component): %sHz.', formatPrefixSI(frequencyOffset(1)));
            
            % Estimate linewidth
            if obj.speedupEnabled
                N = 1;
            else
                N = sig.N;
            end
            lw_eq = zeros(1,N);
            for i=1:N
                [Sphi, f] = periodogram(diff(detrend(obj.results.phaseEstimates(end-L_est:end, i))), [],[],sig.Rs);
                cfact=4*(sin(pi*f/sig.Rs)./f).^2;
                loop_bw = sqrt(2*obj.Kv(i)*sig.Rs/obj.tau1)/(2*pi);
                [~,idx] = min(abs(f-loop_bw));
                try
                    lw_eq(i) = mean(pi*Sphi(idx:idx+200)./cfact(idx:idx+200));
                catch
                    lw_eq(i) = mean(pi*Sphi(idx)./cfact(idx));
                end
            end
            obj.results.linewidths = lw_eq;
            robolog('Estimated combined linewidth (first component): %s Hz', formatPrefixSI(lw_eq(1)));
            
            % Plot the estimates of the phase error
            if obj.draw
                obj.plot()
            end
        end
        
        %> @brief PLL core processing
        %>
        %> Estimates the phase error and applies ompensation to the input signal.
        %>
        %> @param Ein input signal
        %>
        %> @retval Eout signal with phase correction applied
        %> @brief Class constructor
        %>
        %> @param Ein Input complex field. [Vector of double].
        %> @param Ts Symbol period.
        %> @param Kv Loop constant. Can be a scalar or a vector if different values should be used
        %>                 for the different input components (modes). Default: 0.3.
        %> @param tau1 PI filter parameter 1. Default:1/(2*pi*PI_BANDWIDTH) with PI_BANDWIDTH = 10e6
        %> @param tau2 PI filter parameter 2. Default:1/(2*pi*PI_BANDWIDTH) with PI_BANDWIDTH = 10e6
        %> @param refConstellation Reference constellation points. [Vector of complex double].
        %> @param param.initialPhase Phse used to initialize the DDPLL. Default: 0
        %>
        %> @retval E_hat Input signal with phase corrected.
        %> @retval phaseEstimate Phase error estimates.
        function [E_hat, phaseEstimate] = pll(obj, Ein, Ts, Kv, tau1, tau2, refConstellation, initialPhase)
            N = length(Ein);
            
            % Loop filter coefficients
            a1b = [1 Ts/(2*tau1) * ( 1+[-1 1]/tan(Ts/(2*tau2)) ) ];
            
            u_d = 0; % Output of phase detector (residual phase error)
            u_f = 0; % Output of loop filter
            phaseEstimate = initialPhase*ones(N+1,1);
            E_hat = zeros(N,1);
            
            for n=1:N
                u_d1 = u_d;
                E_hat(n) = Ein(n)*exp(-1j*phaseEstimate(n));        % Remove estimate of phase erro from input symbol
                [~,idx] = min(abs(refConstellation-E_hat(n)));      % Slicer (perform hard decision on symbol)
                u_d = imag(E_hat(n)*conj(refConstellation(idx)));   % Generate phase error signal (also called x_n (Meyer))
                u_f = sum(a1b.*[u_f u_d1 u_d]);                     % Process phase error signal in Loop Filter (also called e_n (Meyer))
                phaseEstimate(n+1) = phaseEstimate(n) + Kv*u_f;     % Estimate the phase error for the next symbol
            end
            phaseEstimate = phaseEstimate(1:end-1); % Remove the last estimate, which is unuseful
        end
        
        %> @brief Plot phase estimates
        %>
        %> Plots phase estimates and delta of the phase estimates as a function of the number of samples
        function plot(obj)
            figure('Name', 'DDPLL_v1: Phase estimates');
            subplot(2,1,1);
            plot(obj.results.phaseEstimates);
            title('Unwrapped phase [rad]');
            subplot(2,1,2);
            plot(diff(obj.results.phaseEstimates));
            title('Differential phase [rad]');
        end
    end
end
