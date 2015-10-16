%> @file DDPLL_v1
%> @brief contains implementation of decision-directed PLL
%>
%> @class DDPLL_v1
%> @brief Second order type II decision-directed PLL
%> 
%> @ingroup coreDSP
%> 
%> This class implements a decision-directed PLL for frequency offset
%> correction and carrier phase recovery.  The loop filter is
%> proportional-integrator type and based on the implementation discussed
%> in R. Best, Phase-Locked Loops: Design, Simulation, & Applications,
%> McGraw-Hill 1997.  This description is in the Software PLL chapter.
%>
%> Tuning the feedback parameters:
%> tau1 and tau2 are as defined in standard continuous time PI-PLL theory - 
%> i.e. the loop filter will be described by
%> F(s) = (1+tau2*s)/(tau1*s)
%> Kv is a discrete quantity.  The analogous continuous time loop gain is
%> given by 
%> Kv_cts = 2*Kv/Ts
%> Translation from continuous to discrete is accomplished using the
%> bilinear Z transform, which is why tan(Ts/2*tau) appears in the script.
%> Then loop parameters are given by
%> wn = loop BW in rad/s = sqrt(Kv_cts/tau1)
%> damping_factor = wn*tau2/2
%> 
%> Example
%> @code
%> Rs = 28e9;       %baud rate
%> param.Kv = 0.3;               
%> PI_BW = 100e6;    %Hz
%> PI_damping = 5;
%> param.tau1 = (2*param.Kv*Rs)/((2*pi*PI_BW)^2);
%> param.tau2 = PI_damping*2/(2*pi*PI_BW);
%> param.speedup=1; 
%> param.const_type = 'QAM'
%> @endcode
%> 
%> outputs no results, "plot" function prints frequency offset and
%> plots demodulated phase
%>
%> @author Molly Piels (copied from earlier Robochameleon)
classdef DDPLL_v1 < unit
    
    properties
        nInputs = 1;
        nOutputs = 1;
        
        %> Main control parameters: Kv, tau1, tau2, speedup, const_type, M,
        %> init_phase.  Only M is mandatory, others can be set by default
        param;
        %> Number of samples to demodulate
        N;
        %> Saved phase for x polarization
        phase_x;
        %> Saved phase for y polarization
        phase_y;
        %Baud rate (for plotting, taken from input signal)
        Fb;     
    end
    
    methods
        %> @brief Class constructor
        %> 
        %> Class constructor - params are saved and checked
        %>
        %> @param param structure with loop parameters
        %>
        %> @retval obj instance of DDPLL_v1 class
        function obj = DDPLL_v1(param)
            obj.param = param;
            obj.check_param();
        end
        
        %> @brief Travese function
        %> 
        %> Parses input, calls carrier recovery, parses output
        %>
        %> @param varargin input signal (either 1 for dual pol or 2 for X
        %> and Y)
        %>
        %> @retval out signal with phase correction applied
        function out = traverse(obj, varargin)
            switch numel(varargin)
                case 1
                    sig = varargin{1};
                    sigmat = sig.getNormalized;
                    if sig.N ~= 2
                        error('Input signal must have 2 polarizations')
                    elseif isreal(sigmat(:,1)) || isreal(sigmat(:,2))
                        error('Input signal components must be complex valued')
                    end
                case 2
                    sig1 = varargin{1};
                    sig2 = varargin{2};
                    sigmat = [sig1.getNormalized sig2.getNormalized];
                    if isreal(sigmat(1,:)) || isreal(sigmat(2,:))
                        error('Input signal components must be complex valued')
                    else
                        sig = sig1.set(sigmat(:,1:2));
                    end
                case 4
                    sig1 = varargin{1};
                    sig2 = varargin{2};
                    sig3 = varargin{3};
                    sig4 = varargin{4};
                    sigmat = [sig1.getNormalized sig2.getNormalized sig3.getNormalized sig4.getNormalized];
                    if isreal(sigmat(:,1)) && isreal(sigmat(:,2)) ...
                            && isreal(sigmat(:,3)) && isreal(sigmat(:,4))
                        sig = sig1.set([complex(sigmat(:,1),sigmat(:,2))...
                            complex(sigmat(:,3),sigmat(:,4))]);
                    else
                        error('When using 4 inputs, they must all be real valued')
                    end
            end
            
            if isempty(obj.N)
                obj.N = sig.L;
            end
            [out] = obj.pll(sig);
            
        end
        
        %> @brief Main PLL
        %>
        %> Performs carrier recovery
        %>
        %> @param Ein input signal 
        %>
        %> @retval Eout signal with phase correction applied
        function [Eout] = pll(obj, Ein)
            
            %% Initialization
            obj.Fb = Ein.Rs; Fs = Ein.Fs;
            obj.param.Ts = 1/Ein.Rs;
            
            %% Carrier recovery parameters
            % Generate ideal constellation for decision directed equalizer
            [Constellation, P] = constref(obj.param.const_type, obj.param.M);
            Constellation = Constellation/sqrt(P);
            
            % Loop gain
            if isscalar(obj.param.Kv)
                Kv = repmat(obj.param.Kv,[2 1]);
            elseif isvector(obj.param.Kv) && numel(obj.param.Kv)==2
                Kv = obj.param.Kv;
            else
                error('Incorrect param.crm.Kv.');
            end
            
            % Loop filter coefficients
            a1b = [1 obj.param.Ts/(2*obj.param.tau1) * ( 1+[-1 1]/tan(obj.param.Ts/(2*obj.param.tau2)) ) ];
            
            u_d_x = 0;
            u_f_x = 0;
            
            u_d_y = 0;
            u_f_y = 0;
            
            obj.phase_x = obj.param.init_phase*ones(obj.N+1,1);
            obj.phase_y = obj.param.init_phase*ones(obj.N+1,1);
            
            field=getNormalized(Ein);
            Ex_hat=field(:,1);
            Ey_hat=field(:,2);
            %Ex_hat = pwr.normpwr(Ex_hat);
            %Ey_hat = pwr.normpwr(Ey_hat);

                
            for n=1:obj.N
                u_d_x1 = u_d_x;
                Ex_hat(n) = Ex_hat(n)*exp(-1j*obj.phase_x(n));
                [~,idx] = min(abs(Constellation-Ex_hat(n)));
                u_d_x = imag(Ex_hat(n)*conj(Constellation(idx)));
                u_f_x = sum(a1b.*[u_f_x u_d_x1 u_d_x]);
                obj.phase_x(n+1) = obj.phase_x(n) + Kv(1)*u_f_x;
            end
            if obj.param.speedup
                obj.phase_y = obj.phase_x;
                Ey_hat = Ey_hat(1:obj.N).*exp(1i*(-obj.phase_y(1:obj.N)));
            else
                for n=1:obj.N
                    u_d_y1 = u_d_y;
                    Ey_hat(n) = Ey_hat(n)*exp(-1j*obj.phase_y(n));
                    [~,idx] = min(abs(Constellation-Ey_hat(n)));
                    u_d_y = imag(Ey_hat(n)*conj(Constellation(idx)));
                    u_f_y = sum(a1b.*[u_f_y u_d_y1 u_d_y]);
                    obj.phase_y(n+1) = obj.phase_y(n) + Kv(2)*u_f_y;
                end
            end
            
            
            Eout = signal_interface([Ex_hat(1:obj.N) Ey_hat(1:obj.N)], struct('Rs', obj.Fb, 'Fs', Fs, 'P', Ein.P, 'Fc', Ein.Fc));
            
            
        end
        
        %> @brief Plot results
        %>
        %> Plots phase as a function of time, estimates frequency offset
        function plot(obj)
            figure(2833);
            plot(0:obj.N,obj.phase_x);
            L_est = min(1e4,numel(obj.phase_x));
            est_f_off = (obj.phase_x(end)-obj.phase_x(end-L_est+1))/(2*pi*L_est)*obj.Fb;
            fprintf('Estimated frequency offset %0.0f MHz\n',est_f_off/1e6);    
            %obj.results.f_off=est_f_off/1e6;
        end
        
        %> @brief for compatibility
        %> 
        %> Does nothing
        function initialize(obj, sig)
            return
        end
        
        %> @brief Checks carrier recovery parameters
        %>
        %> Checks carrier recovery parameters.  Assigns default values if
        %> user does not specify.
        function check_param(obj)
            %notify user we're using default values
            if ~any(isfield(obj.param, {'Kv', 'tau1', 'tau2', 'init_phase', 'speedup'}))
                warning('Using at least one default parameter value')
            end
            
            obj.param.Kv = paramdefault(obj.param, 'Kv', 0.3);
            PI_BW = 10e6;
            obj.param.tau1 = paramdefault(obj.param, 'tau1', 1/(2*pi*PI_BW));
            obj.param.tau2 = paramdefault(obj.param, 'tau2', 1/(2*pi*PI_BW));
            obj.param.init_phase = paramdefault(obj.param, 'init_phase', 0);
            obj.param.speedup = paramdefault(obj.param, 'speedup', 1);
            
            obj.param.const_type = paramdefault(obj.param, 'const_type', 'QAM');

        end
        
    end
end