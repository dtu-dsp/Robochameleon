%> @file LinChBulk_v1.m
%> @brief Contains implementation of linear channel model
%>
%> @class LinChBulk_v1
%> @brief Linear channel model
%> 
%>  @ingroup physModels
%>
%> Linear fiber optic channel model with polarization (mode) mixing, 
%> chromatic dispersion, PMD, and loss
%> 
%> __Observations__
%>
%> 1. Number of modes supported by fiber is set by the dimension of the input signal
%>
%> 2. Fiber parameters are taken from a look-up table for SMF28 unless
%> otherwise specified.  
%> 
%> 3. Mode mixing is based on random matrix generation unless otherwise
%> specified.
%> 
%> 4. The general assumption is that the fiber supports "principal modes"
%> and that these have a bandwidth that is larger than the signal bandwidth.
%> This is fine for SMF, but potentially problematic for multimode fiber.
%> 
%>
%> __Examples__
%> 
%> @code
%> param = struct('D', 1e-6, 'S', .0092, 'L', 40, 'loss', .34);
%> channel = LinChBulk_v1(channel);
%> @endcode
%>
%> Will construct a 40km channel with .34 dB/km loss and negligible 1st
%> order dispersion (typical parameters at 1310).  These parameters will 
%> be fixed regardless of the wavelength of the input signal.  The code
%>
%> @code
%> param = struct('L', 40);
%> channel = LinChBulk_v1(channel);
%> signal = signal_interface(field, struct('Fc', const.c/1310e-9, ...));
%> sigout = channel.traverse(signal);
%> @endcode
%>
%> Will also construct a 40km channel with .34 dB/km loss and negligible 1st
%> order dispersion.  If the input signal were at 1550 instead, the
%> dispersion, loss, etc. would be different.
%>
%> To remove the effect of polarization mixing, specify the Jones matrix of
%> the fiber as an identity matrix:
%> @code
%> param = struct('L', 40, 'U', eye(2));
%> channel = LinChBulk_v1(channel);
%> @endcode
%>
%> @author Molly Piels
%> @version 2
classdef LinChBulk_v1 < unit

    
    properties
        %> Number of outputs
        nOutputs = 1;
        %> Number of inputs
        nInputs = 1;
        
        %> dispersion coeff. (ps/nm km)
        D = nan;
        %> 2nd order dispersion coeff. (ps/nm^2 km)
        S = 0;
        %> length (km)
        L = 0;
        %> Jones matrix 
        U = nan;
        %> modulus of DGD/PMD vector (s)
        DGD = 0;
        %> vector of DGDs (s)
        tau = nan;
        %> Matrix of principal modes
        P = nan;
        %> How to specify DGD {'set' | 'random'}
        DGD_mode = 'set';
        %> loss (dB/km)
        loss = nan;       
    end
    
    methods (Static)
        
        %> @brief Generates a random unitary matrix
        %>  
        %> Generates a random unitary matrix.  If called many
        %> times, the set of returned matrices will have appropriately 
        %> statistically distributed eigenvalues. This is important for 
        %> channel capacity calculations.  The algorithm is from
        %> F. Mezzadri, "How to generate random matrices from the classical 
        %> compact groups,” arXiv Prepr. math-ph/0609050, vol. 54, no. 5, 
        %> pp. 592–604, 2006.
        %>
        %> @param N matrix dimension
        %>
        %> @retval U NxN unitary matrix
        function U=random_unitary(N)
            A=(randn(N)+1i*randn(N))/sqrt(2);
            [Q,R]=qr(A);
            D=diag(R);
            ph=D./abs(D);
            U=Q*diag(ph);
        end
        
        %> @brief Generates a random hermitian matrix
        %>  
        %> Generates a random Hermitian matrix with zero trace
        %>
        %> @param N matrix dimension
        %>
        %> @retval H NxN Hermitian matrix
        function H=random_hermitian(N)
            A=(randn(N)+1i*randn(N))/sqrt(2);
            H=(A+A')/2;
            eta_zero=trace(H);
            H=H-eta_zero*eye(N)/(N);
        end
        
        %> @brief Converts unitary matrix to equivalent rotation matrix
        %>  
        %> Maps U in C^2 to R in R^3 - returns rotation part of Mueller
        %> matrix of fiber given a fiber Jones matrix.  Only applies to 2x2
        %> Jones matrices.  
        %>
        %> @param U Jones matrix (must be 2x2)
        %>
        %> @retval R rotation matrix
        function R = stokes_from_U(U)
            
            %maps rotation matrix from unitary matrix
            alpha=U(1,1);
            beta=U(1,2);
            
            R = [alpha*conj(alpha)-beta*conj(beta) 2*real(conj(alpha)*beta) 2*imag(alpha*conj(beta));...
                -2*real(alpha*beta) real(alpha^2-beta^2) imag(alpha^2+beta^2);...
                2*imag(alpha*beta) imag(beta^2-alpha^2) real(alpha^2+beta^2)];
            
        end
        
        %> @brief Dispersion lookup table
        %>
        %> Dispersion lookup table based on Corning SMF 28
        %>
        %> @param lambda wavelength in m
        %>
        %> @retval D_out in ps/(nm km)
        function D_out = D_lookup(lambda)
            D_out=0.088/4*(lambda*1e9-(1317)^4/(lambda*1e9)^3);     %for SMF 28
        end
        
    end
    
    methods
        %>  @brief Class constructor
        %>
        %> Constructs an object of type LinChBulk
        %> 
        %> Generally, if fiber parameters are not specified, the model will
        %> assume SMF-28 and use a lookup table based on the input signal's
        %> wavelength.
        %>
        %> @param param.D          Dispersion coefficient [ps/nm*km].
        %> @param param.S          Dispersion slope [(ps/nm^2 km)] [Default 0].
        %> @param param.L          Fiber length [km] [Default: 0].
        %> @param param.U          Unitary matrix describing mode mixing [au] [Default: randomly generated]
        %> @param param.DGD        Modulus of DGD/PMD vector [s] [Default: 0]
        %> @param param.DGD_mode   How to interpret param.DGD: 'set' = the DGD is param.DGD (only makes sense for SMF); 'random' = the DGD is drawn randomly from an appropriate PDF with this mean. [Default: set]
        %> @param param.loss       Fiber loss [dB/km]
        %> @param param.tau        Vector of differential group delays to apply [s]
        %> @param param.P          Matrix describing polarization alignment of DGD vector [au] [Default: randomly generated]
        %>
        %> @retval obj      An instance of the class ClassTemplate_v1
        function obj = LinChBulk_v1(param)
            obj.setparams(param);
        end
        
        %> @brief Traverse function
        %>  
        %> Applies polarization mixing, then chromatic dispersion, then
        %> PMD, then loss
        %>
        %> @retval out signal after propagation through channel
        %> @retval results.Jones Jones matrix of fiber 
        %> @retval results.PMD modulus of PMD vector
        %> @retval results.Stokes Rotation matrix of fiber in Stokes space (SMF only)
        function out = traverse(obj,in)
            
            %CD
            ECD=obj.cd_loading(in);
            
            %PMD/polarization mixing
            if isnan(obj.U)
                obj.U=obj.random_unitary(in.N);
            end
            if (obj.DGD>0)||(~any(isnan(obj.tau)))
                [EPMD, mod_tau]=obj.pmd_loading(ECD);
            else
                EPMD=ECD*obj.U;
                mod_tau=0;
            end
            
            %loss
            if isnan(obj.loss)
                if in.Fc>0
                    lambda=1e9*const.c/in.Fc;
                    wl_LUT=[1310 1383 1490 1550 1625];
                    att_LUT=[0.34 0.33 0.225 0.195 0.215];
                    [~,idx]=min(abs(lambda-wl_LUT));
                    obj.loss=att_LUT(idx);
                    robolog('Setting channel loss from look-up table for SMF-28', 'WRN')
                else
                    obj.loss=0;
                    robolog('Channel input has zero carrier frequency, assuming lossless', 'WRN')
                end
            end
            loss_lin=10^(-obj.L*obj.loss/10);
            out = EPMD*(loss_lin*eye(in.N));
            
            if in.N==2
                obj.results = struct('Jones', obj.U, 'Stokes', obj.stokes_from_U(obj.U), 'PMD', mod_tau*obj.DGD/sqrt(in.N-1));
            else
                obj.results = struct('Jones', obj.U, 'PMD', mod_tau*obj.DGD/sqrt(in.N-1));
            end
        end
        
        %> @brief Chromatic dispersion loading
        %>
        %> Chromatic dispersion loading - operates in frequency domain
        %>
        %> @param Ein input signal (signal_interface)
        %>
        %> @retval Eout output signal (signal_interface)
        %> @retval H Transfer function of dispersion operator
        function [Eout,H] = cd_loading(param, Ein)
            
            c = const.c;
            %lambda = param.lambda;
            if Ein.Fc>0
                lambda=c/Ein.Fc;
            else
                lambda=1550e-9;
                warning('Channel input has zero carrier frequency, assuming 1550nm')
            end
            if isnan(param.D)
                param.D=param.D_lookup(lambda);
            end
            DL = sum(param.D.*param.L)*1e-3; % Convert to base SI units (ps/nm -> 10^-3 s/m)
            SL = sum(param.S.*param.L)*1e+6; % Convert to base SI units (ps/nm^2 -> 10^6 s/m^2)
            CD = [DL SL+2*DL/lambda]; % Dispersion coefficients
            Nfft = Ein.L;
            omega = 2*pi*[(0:Nfft/2-1),(-Nfft/2:-1)]'/(Nfft/Ein.Fs) ;
            
            H = exp(-1j/2*CD(1)*(lambda^2/(2*pi*c))*omega.^2 ...
                -1j/6*CD(2)*(lambda^2/(2*pi*c))^2*omega.^3); % Taylor expansion
            
            Eout = fun1(Ein,@(E)ifft(H.*fft(E,Nfft),Nfft));
            
        end
        
        %> @brief PMD loading
        %> 
        %> PMD loading
        %>
        %> Modes of operation: 
        %> PMD can either be set ('set' mode) or drawn from an appropriate
        %> statistical distribution ('random' mode).
        %> In 'set' mode, for a 2-mode fiber, you specify the modulus of the DGD
        %> vector (DGD property), and the associated delays are +/- tau/2.  For
        %> N-mode fiber, you can either set the modulus (DGD property) or specify
        %> the actual delays (tau property)
        %> In random mode, model draws from a chi distribution with <# of modes>
        %> degrees of freedom for actual modulus of PMD vector (Maxwell if
        %> N=2).
        %>
        %> Main method:
        %> Delays are applied as shifts to randomly oriented principal modes.  See
        %> J. P. Gordon and H. Kogelnik, "PMD fundamentals: Polarization mode
        %> dispersion in optical fibers," Proc. Natl. Acad. Sci., vol. 97, no. 9,
        %> pp. 4541–4550, 2000.
        %> or
        %> K.-P. Ho and J. M. Kahn, "Statistics of Group Delays in Multimode
        %> Fiber with Strong Mode Coupling," J. Light. Technol., vol. 29, pp.
        %> 3119–3128, 2011.
        %>
        %> @param U Jones matrix of fiber
        %> @param in input signal (signal_interface class)
        %>
        %> @retval Eout output signal
        %> @retval mod_tau modulus of DGD vector
        function [Eout, mod_tau] = pmd_loading(obj, in)
            
            %get modulus of PMD vector
            switch obj.DGD_mode
                case 'random'
                    %Get modulus of DGD vector
                    %coded obscurely to generalize to large N correctly.
                    %For N=2, draws a modulus of tau from a Maxwellian distribution
                    mod_tau=random('nakagami', in.N/2, in.N);       
                case 'set'
                    mod_tau=1;
                otherwise
                    error('Undefined DGD mode')
            end
            
            %get associated delays and principal modes
            if in.N==2
                %choose delays using obj.DGD if not otherwise specified
                if isnan(obj.tau)
                    delays=[-mod_tau/2, mod_tau/2]*obj.DGD;
                    obj.tau = delays;
                    if any(isnan(obj.P))
                        P=obj.random_unitary(2);
                        obj.P = P;
                    else
                        P = obj.P;
                    end
                %assign delays using obj.tau if specified and in set mode
                elseif strcmp(obj.DGD_mode, 'set')
                    delays = obj.tau;
                    if any(isnan(obj.P))
                        P=obj.random_unitary(2);
                        obj.P = P;
                    else
                        P = obj.P;
                    end
                %If user in random mode but also setting delays, they are
                %either using this incorrectly, OR using a linch object
                %twice.  Figure out which one, act accordingly.
                else
                    try 
                        delays = obj.tau;
                        P = obj.P;
                    catch
                        error('Cannot set delays in random DGD mode');
                    end
                end
            else
                %choose delays using obj.DGD if not otherwise specified
                if isnan(obj.tau)
                    H=obj.random_hermitian(in.N);
                    [P, delays] = eig(H);
                    delays=diag(delays);
                    ampl=(mod_tau*obj.DGD/sqrt(in.N-1))/(in.N*sqrt(sum(delays.^2)));
                    delays=ampl*delays;
                    %save
                    obj.tau = delays;
                    obj.P = P;
                elseif strcmp(obj.DGD_mode, 'set')
                    delays = obj.tau;
                    if any(isnan(obj.P))
                        H=obj.random_hermitian(in.N);
                        [P,~] = eig(H);
                        obj.P = P;
                    else
                        P = obj.P;
                    end             
                %If user in random mode but also setting delays, they are
                %either using this incorrectly, OR using a linch object
                %twice.  Figure out which one, act accordingly.
                else
                    try
                        delays = obj.tau;
                        P = obj.P;
                    catch
                        error('Cannot set delays in random DGD mode');
                    end
                end
            end
            %time-domain: shifts (faster but less granularity available)
            %T=min(delays):1/(in.Fs):max(delays);
            % for jj=1:length(delays)
            %      [~, inds(jj)]=min(abs(T-delays(jj)));
            %end
            
            %frequency domain
            Nfft = in.L;
            omega = 2*pi*[(0:Nfft/2-1),(-Nfft/2:-1)]'/(Nfft/in.Fs) ;
            
            %shift/spread input
            %E_sh(1:N) all correspond to the same spatial mode at the input
            E_sh=zeros(in.L, in.N^2);
            F_in=getScaled(in);     %be sure...
            %No point having high-precision delays if input isn't high-precision
            c=whos('F_in');
            switch c.class
                case 'single'
                    omega = single(omega);
                    delays = single(delays);
            end
            
            F_in_spec = fft(F_in, Nfft, 1); %calculate N times, not N^2 times
            for jj=1:in.N^2
                mode_no=ceil(jj/in.N);
                delay_no=mod(jj-1, in.N)+1;
                %E_sh(:,jj)=circshift(F_in(:,mode_no), inds(delay_no));
                E_sh(:,jj)=ifft(F_in_spec(:,mode_no).*exp(-1i*omega*delays(delay_no)), Nfft);   %times faster than bsxfun(@times)
            end
                        
            %add
            Fnew=zeros(size(F_in));
            for jj=1:in.N
                delay_no=mod(jj-1, in.N)+1;
                %draw from PM number delay_no
                mode_set=(1:in.N:in.N^2)+delay_no-1;
                %<field launched into PM(mode number) by our N inputs><appropriate
                %weights>, added = appropriately time-delayed outputs in PM 1, 2, ... N
                Fnew(:,jj)=E_sh(:,mode_set)*P(delay_no, :).';
                %
            end
            %so Fnew is in PM space
            
            %Move from PM space to output spatial modes
            P_out=obj.U*P;
            Fout=Fnew*P_out;
            
            %track power
            P_out = in.PCol;        % allocate
            P_new = pwr.meanpwr(Fout);
            Pn_in = 10.^(([in.PCol.P_dBW]-[in.PCol.SNR_dB])/10);        %input Pn in linear units
            Pn_out = (obj.U.*conj(obj.U))*Pn_in.';                        %power transfer matrix*input noise powers
            SNR_out = 10*log10(P_new./Pn_out');                         %convert to dB
            for jj=1:in.N
                P_out(jj) = pwr(SNR_out(jj), {P_new(jj), 'W'});
            end
            
            Eout = signal_interface(Fout, struct('Fs', in.Fs, 'Rs', in.Rs, 'Fc', in.Fc, 'PCol', P_out));
        end
    end
    
end