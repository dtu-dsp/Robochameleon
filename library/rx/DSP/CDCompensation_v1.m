%> @file CDCompensation_v1.m
%> @brief FFT-based chromatic dispersion compensation.
%>
%> @class CDCompensation_v1
%> @brief FFT-based chromatic dispersion compensation.
%> 
%> @ingroup coreDSP
%> 
%> FFT-based chromatic dispersion compensation.  Applies dispersion
%> transfer function to signal - reverse signs to compensate (e.g. if the
%> fiber has a dispersion slope of 16.3 ps/nm/km, set obj.D = -16.3).
%> 
%> @author Robert Borkowski <rbor@fotonik.dtu.dk>
%> @version 1
%> Technical University of Denmark
%> 17.12.2014
classdef CDCompensation_v1 < unit
    
    properties (Hidden=true)
        nInputs = 1;
        nOutputs = 1;
    end
    
    properties
        %> System length, km
        L;      
        %> Average dispersion parameter, ps/nm/km
        D = -17; 
        %> Dispersion slope, ps/nm^2/km
        S = 0; 
        %> Compensation wavelength, m
        lambda = 1550e-9; 
        %> FFT size, Sa
        Nfft = 0;
    end
    
    
    
    methods
        
        %>  @brief Class constructor
        %>
        %>  Class constructor
        %>
        %>  Example:
        %>  @code
        %>  CDcomp = CDCompensation_v1(struct('L', 1e3, 'lambda', 1560e-9));
        %>  @endcode
        %>
        %> @param param.D Dispersion parameter (ps/nm/km) (default 17)
        %> @param param.S Dispersion slope, ps/nm^2/km (default 0)
        %>
        %> @retval CDCompensation object
        function obj = CDCompensation_v1(params)
            setparams(obj,params);
            if isnan(obj.D), obj.D = 0; end
            if isnan(obj.S), obj.S = 0; end
            if obj.S
                robolog('Dispersion slope compensation never tested. Use with caution.', 'WRN');
            end
            %TODO add obj.Nfft setting
        end
        
        %>  @brief Traverse function
        %>
        %>  Applies CD transfer function in the frequency domain to the
        %>  signal
        %> 
        %> @param in Signal to be compensated
        %>
        %> @retval out compensated signal
        %> @retval results no results
        function out = traverse(obj,in)
            if obj.Nfft % If obj.Nfft is nonzero
                % Set the specified FFT size
                Nfft = obj.Nfft; %#ok<*PROP>
            else
                % Automatically choose FFT size based on the signal size
                Nfft = in.L;
            end            
            if mod(Nfft/2, 1)==0
                omega = 2*pi*[(0:Nfft/2-1),(-Nfft/2:-1)]'/(Nfft/in.Fs);
            else
                omega = 2*pi*[(0:Nfft/2-.5),(-Nfft/2:-1)]'/(Nfft/in.Fs);
            end
            H = cdtransfun(obj,omega);
            out = fun1(in,@(s)ifft(H.*fft(s,Nfft),Nfft));
        end        
        
        %>  @brief Calculate CD transfer function
        %>
        %>  Calculate CD transfer function.
        %>
        %> @param omega angular frequencies at which to calculate transfer function
        %>
        %> @retval H transfer function
        function H = cdtransfun(obj,omega)
            DL = obj.D.*obj.L*1e-3; % Convert to base SI units (ps/nm -> s/m)
            SL = obj.S.*obj.L*1e+6;
            SL = SL+2*DL/obj.lambda;
            dispersion = [DL SL];
            
            phi = zeros(size(omega));
            for term=1:numel(dispersion)
                phi = phi + dispersion(term)/factorial(term+1) * (obj.lambda^2/(2*pi*const.c))^term * omega.^(term+1);
            end
            H = exp(1j*phi);
%             terms = 1:numel(dispersion);
%             phi = sum(dispersion./factorial(terms+1) * (lambda^2/(2*pi*const.c)).^terms * omega.^(terms+1));     
        end
        
    end
    
    
    
end