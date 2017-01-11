%>@file NonlinearChannel_v1.m
%>@brief Nonlinear fiber optical channel model class definition
%>
%>@class NonlinearChannel_v1
%>@brief Nonlinear fiber optical channel model using SSF method class
%> 
%>  @ingroup physModels
%>
%> This class implements the optical channel propagation model based on
%> the numeric solution of the Non-Linear Schrodinger Equation (NLSE)
%> using Split Step Fourier (SSF) method.
%>
%>
%> __Observations:__
%>
%> 1. Please, pay attention to the dimensions. Make sure that the
%> parameters are passed with the correct value in the correspondent
%> unit.
%>
%> 2. For the traverse method, only the two first columns of the signal
%> vector will be considered (i.e., two polarization modes)
%>
%> 3. Polarization mixing is implemented as a unitary transformation
%> between spans.  Polarization mode dispersion is not currently included.
%> The core fiber model comes from ssprop from the Photonics Research 
%> Laboratory at the University of Maryland (Baltimore).  ssprop has PMD
%> included, but this unit does not have an interface to support it.
%>
%>
%> __Conventions:__
%> * Dispersion coeff.: D = 2*pi*c/lambda^2, (2.3.5)                                    [1]
%> * Dispersion slope : S = (2*pi*c/lambda^2)^2*Beta3 +(4*pi*c/lambda^3)*Beta2, (2.3.13)[1]
%> * ASE power calculation: Pase = 2*nsp*h*f0*nSpans*(G-1)*BWopt, (6.5.18)               [1]
%>                        - f0 = c/lambda, BWopt = bandwidth of interest
%>                        - NF = 2*nsp*(G-1)/G = 2nsp (aprox.), (6.1.19)                [1]
%>
%>
%> __Example:__
%> @code
%>   % Build a channel with default parameters
%>   fiberChannel = NonlinearChannel_v3();
%>
%>   sigIn = createDummySignal_v1()
%>
%>   sigOut = fiberChannel.traverse(sigIn);
%> @endcode
%>
%> __Advanced Example:__
%> @code
%>   param.nlinch.nSpans = 2;
%>   param.nlinch.dispersionCompensationEnabled = 1;
%>   param.nlinch.polarizationMixingEnabled = 0;
%>   param.nlinch.L = [50 80];
%>   param.nlinch.stepSize = 5;
%>   param.nlinch.iterMax = 15;
%>   param.nlinch.alpha = 0.2;
%>   param.nlinch.D = 17;
%>   param.nlinch.S = [0.1 0.2];
%>   param.nlinch.gamma = 1.7;
%>   param.nlinch.EDFANF = [3 5];
%>   param.nlinch.EDFAGain = [10 16];
%>
%>   fiberChannel = NonlinearChannel_v3(param.nlinch);
%>
%>   sigIn = createDummySignal_v1()
%>
%>   sigOut = fiberChannel.traverse(sigIn);
%> @endcode
%>
%> __References:__
%>
%> * [1] Agrawal, Gowind P.: Fiber-Optic Communication Systems. 3rd : John
%> Wiley & Sons, 2002.
%> * [2] http://www.photonics.umd.edu/software/ssprop/
%>
%> @author Edson Porto da Silva
%> @author Simone Gaiarin
%>
%> @version 3
classdef NonlinearChannel_v1 < unit
....
    properties

        %> Number of fiber spans (fiber + amplifier)
        nSpans = 1;
        %> Length of each span in km: 1-by-nSpans vector;
        L = 80;
        %> Step size for the Split Step Fourier Method in km: 1-by-nSpans vector;
        stepSize = 10;
        %> Maximum of split step iterations
        iterMax = 10;
        %> Fiber attenuation coefficient for polarization (a) in km^-1: 1-by-nSpans vector;
        alphaa = 0.2;
        %> Fiber attenuation coefficient for polarization (b) in km^-1: 1-by-nSpans vector;
        alphab = 0.2;
        %> Nonlinear coefficient of the fiber in W^-1*km^-1;
        gamma = 1.2;
        %> Dispersion coefficient
        D = 17;
        %> Dispersion slope
        S = 0;
        %> Gain of each optical amplifier (linear): 1-by-nSpans vector;
        EDFAGain = 16;
        %> Noise figure of the optical amplifiers (linear): 1-by-nSpans vector;
        EDFANF = 3;
        %> Dispersion compensation 0/1
        dispersionCompensationEnabled = 0;
        %> Fraction of chromatic dispersion to compensate
        dispersionCompensationFraction = 1;
        %> Polarization Mixing: 0/1
        polarizationMixingEnabled = 0;
        %> SSF precision flag
        doublePrecisionEnabled = 1;
        %> Don't put EDFA
        noEDFAEnabled = 0;
        %> Number of inputs
        nInputs = 1;
        %> EDFA spontaneous emission factor (population inversion factor)
        nOutputs = 1;
    end
    
    methods (Static)
        % Arbitrary polarization state rotation:
        function out = randPolRotation(in,lambda)
            
            % FIXME Why constant here?
            MeanDGBperBlock = 5.2e-12;              % Mean DGD per spam of ~80 km = 11.2 ps. Reference: Long-Term Observation of PMD and SOP on Installed Fiber Routes, doi: 10.1109/LPT.2013.2290473
            Wc             = 2*pi*const.c/lambda;   % Angular frequency of the carrier
            
            theta = pi/2*rand(1,1);
            phi   = pi*rand(1,1);
            
            ROT = [cos(theta)*cos(phi)-1i*sin(theta)*sin(phi) -sin(theta)*cos(phi)+1i*cos(theta)*sin(phi)
                sin(theta)*cos(phi)+1i*cos(theta)*sin(phi)  cos(theta)*cos(phi)+1i*sin(theta)*sin(phi)];
            
            % Sample from a random variable with Maxwellian distribution:
            % FIXME Should have 2 d.f.
            Maxwell = sqrt(randn(1,1).^2 + randn(1,1).^2 + randn(1,1).^2)*MeanDGBperBlock/sqrt(2/pi)/2;
            
            % Random DGD unitary matrix:
            P = [exp(1i*Wc*Maxwell/2) 0; 0 exp(-1i*Wc*Maxwell/2)];
%             FiberSliceMatrix = ROT*P*inv(ROT);
            FiberSliceMatrix = ROT*P/ROT;
            out = FiberSliceMatrix*in;
        end
    end
    
    methods

    %> @brief Class constructor
    %>
    %> Constructs an object of type NonlinearChannel_v1.
    %>
    %> @param param.nSpans                              Number of spans to be simulated.
    %> @param param.L                                  Span lengths [km]. Vector [1 x nSpans] or scalar. [Default: 80]
    %> @param param.stepSize                           Step size for the SSF method [km]. Vector [1 x nSpans] or scalar. [Default: 10]
    %> @param param.iterMax                            Maximum of SSF iterations per step size [km]. [Default: 10].
    %> @param param.alpha                              Fiber attenuation coefficients [dB/km]. Vector [1 x nSpans] or scalar. [Default: 0.2]. Not used if alphaa and alphab specified.
    %> @param param.alphaa                             Fiber attenuation coefficients polarization X [dB/km]. Vector [1 x nSpans] or scalar. [Default: 0.2].
    %> @param param.alphab                             Fiber attenuation coefficients polarization Y [dB/km]. Vector [1 x nSpans] or scalar. [Default: 0.2]
    %> @param param.D                                  Fiber dispesion coefficients [ps/nm/km].Vector [1 x nSpans] or scalar. [Default: 17]
    %> @param param.S                                  Fiber dispesion slope [ps/nm^2/km]. Vector [1 x nSpans] or scalar. [Default: 0.1]
    %> @param param.gamma                              Fiber nonlinear coefficients [W^-1*km^-1]. Vector [1 x nSpans] or scalar. [Default: 1.2]
    %> @param param.noEDFAEnabled                      If true and there is only one link, the EDFA is not put at the end of the link  
    %> @param param.EDFANF                             EDFA's noise figure [dB]. Vector [1 x nSpans] or scalar. [Default: 16]
    %> @param param.EDFAGain                           EDFA's gain [dB]. Vector [1 x nSpans] or scalar. [Default: 3]
    %> @param param.dispersionCompensationEnabledion   Dispersion compensation flag. [Default: 0]
    %> @param param.dispersionCompensationFraction     Fraction of span dispersion to compensate. [Default: 1]
    %> @param param.polarizationMixingEnabled          Polarization mixing flag. [Default: 0]
    %> @param param.doublePrecisionEnabled             Precision flag. Set to 0 for speed. [Default: 1]
    function obj = NonlinearChannel_v1(param)
        if ~exist('param', 'var')
            param = struct();
        end
        if ~(isfield(param, 'alphaa') && isfield(param, 'alphaa')) && isfield(param, 'alpha')
            param.alphaa = param.alpha;
            param.alphab = param.alpha;
            param = rmfield(param, 'alpha');
        end
        % Automatically assign params to matching properties
        obj.setparams(param);
        if obj.noEDFAEnabled && obj.nSpans > 1
            robolog('It''s not possible to not put EDFA when there is more than one span.', 'ERR');
        end
        % If more than one span, exapand the parameters in rows
        % Input:  param.nSpans = 2
        %         param.L = 80;
        % Result: param.L = [80 80];
        if obj.nSpans > 1
            propNames = {'L', 'alphaa', 'alphab', 'D', 'S', 'gamma', 'EDFAGain', 'EDFANF'};
            for prop=propNames
                prop=prop{:};
                if length(obj.(prop)) == 1
                    obj.(prop) = repmat(obj.(prop), 1, param.nSpans);
                end
            end
        end
    end
        
    function out = traverse(obj, in)
        
        cKms       = const.c*1e-3;
        lambda     = cKms/in.Fc;                        % Central lambda in km;
        beta2      = -obj.D*lambda^2/(2*pi*cKms);       % Beta2 dispersion polynomial coefficient (chromatic dispersion)
        beta3      = beta2.^2./obj.D.*(obj.S./obj.D + 2/lambda);  % Beta3 dispersion polynomial coefficient (dispersion slope)
        betaa      = [zeros(2,obj.nSpans); beta2; beta3]; % Fiber dispersion polynomial for polarization (a): 3-by-nSpans vector;
        betab      = [zeros(2,obj.nSpans); beta2; beta3]; % Fiber dispersion polynomial for polarization (b): 3-by-nSpans vector;
        nz         = ceil(obj.L/obj.stepSize);         % Number of steps to take per span of fiber
        dz         = obj.L./nz;                          % Distance per step (km)
        alphaalin     = obj.alphaa/(10*log10(exp(1))); % Fiber attenuation coefficient polarization (b): convert dB/km to 1/km
        alphablin     = obj.alphab/(10*log10(exp(1))); % Agrawal 5th (2.5.3)

        robolog(['Nonlinear channel:\n' ...
            '  Average step size: %d km\n' ...
            '  Number of fiber spans: %d).'], mean(dz), obj.nSpans);
        
        % Manage single polarization signals. Add a zero polarization and set PCol.
        if in.N == 1
            robolog('Add second null polarization to signal_interface');
            newParam = in.params();
            newParam.PCol = [in.P pwr(-inf, -inf)];
            zeroPol = zeros(length(in.get), 1);
            in = signal_interface([in.get zeroPol], newParam);
        end
        
        for k = 1:obj.nSpans
            
            % Retrieve the field of input signal or the output of the n-th span
            x = in(:,1);                         % Polarization X (Pol.x)
            y = in(:,2);                         % Polarization Y (Pol.y)
            
            % Pass the signal through a span of fiber using split step fourier method (SSFM)
            % and scale the power (PCOl) properly
            robolog('Span #%d input       - Total power: %1.2f dBm. OSNR: %1.1f', k, in.P.Ptot, in.P.getOSNR(in));
            Pin =  mean(pwr.meanpwr([x y]));
            if obj.doublePrecisionEnabled
                [x,y] = sspropv_robo2(x,y,in.Ts,dz(k),nz(k),alphaalin(k),alphablin(k),...
                    -betaa(:,k),-betab(:,k),-obj.gamma(k),[0,0],'circular',...
                    obj.iterMax); % Obs: signs of beta and gamma are inverted to keep compatibility with sspropv.
            else
                [x,y] = sspropv_robo2(single(x),single(y),in.Ts,dz(k),nz(k),alphaalin(k),alphablin(k),...
                    -betaa(:,k),-betab(:,k),-obj.gamma(k),[0,0],'circular',...
                    obj.iterMax); % Obs: signs of beta and gamma are inverted to keep compatibility with sspropv.
            end
            Pout =  mean(pwr.meanpwr([x y]));
            newPCol = in.PCol*(Pout/Pin);
            in=in.set([x, y]);
            in=in.set('PCol', newPCol);
            robolog('Span #%d output      - Total power: %1.2f dBm. OSNR: %1.1f', k, in.P.Ptot, in.P.getOSNR(in));
            
            if ~obj.noEDFAEnabled
                % Amplify the output of the span using the EDFA block in order to track power and OSNR
                param.edfa.gain = obj.EDFAGain(k);
                param.edfa.NF = obj.EDFANF(k);
                edfa = EDFA_v1(param.edfa);
                in = edfa.traverse(in);
                robolog('Span #%d EDFA output - Total power: %1.2f dBm. OSNR: %1.1f', k, in.P.Ptot, in.P.getOSNR(in));
            end
            
            % Compensated links (ideal DCF: no loss, no nonlinearity)
            % Obs: signs of beta and gamma are inverted to keep compatibility with sspropv.
            if obj.dispersionCompensationEnabled
                x = in(:,1);
                y = in(:,2);
                [x,y] = sspropv_robo2(x,y,in.Ts,obj.dispersionCompensationFraction*obj.L(k),1,0,0,...
                    betaa(:,k),betab(:,k),0,[0,0],'circular',...
                    obj.iterMax);
                % Power shouldn't change. But let's log it to be sure.
                Power = sum(abs(x).^2 +abs(y).^2)/length(x);
                robolog('Span #%d CD output   - Total power: %1.2f dBm.', k, 10*log10((Power/1e-3)));
                in=in.set([x, y]);
            end
            
            if obj.polarizationMixingEnabled
                % Polarization Mixing:
                U = LinChBulk_v1.random_unitary(2);
                in = in*U;
            end
            
        end

        % Set output signal_interface. The power is already correct because we extracted it
        % from a signal_interface with the correct power and possibly we passed it through two
        % block which don't alter power and SNR
        %out=in.set([x, y]);
        out=in;
    end
   end
end
