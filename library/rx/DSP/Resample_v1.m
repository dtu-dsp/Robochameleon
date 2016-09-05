%> @file Resample_v1.m
%> @brief Resampling
%>
%> @class Resample_v1
%> @brief Resampling
%>
%> @ingroup coreDSP
%> 
%> RESAMPLER resamples the signal. Use normal and fast matlab (arbitrary clock phase), 
%> a clock phase based on the Gardner estimate, or spline interpolation
%> 
%> @author Miguel Iglesias Olmedo
%> @version 1
classdef Resample_v1 < unit
    
    properties
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;
        %> method {'matlab' | 'gardner' | 'spline'}
        method = 'spline';
        %> Sampling frequency of output signal (Hz)
        newFs;
    end
    methods
        %> @brief Class constructor
        %>
        %> @param param.method Resampling method ['matlab' | 'gardner'|'spline']; [default spline]
        %> @param param.newFs New sampling frequency [Hz]
        function obj = Resample_v1(params)
            setparams(obj,params,{'newFs'}); %#ok<*EMCA>
        end
        
        %> @brief main
        function out = traverse(obj, sig)
            switch lower(obj.method)
                case 'gardner'
                    sig = sig.fun1(@(x)Resample_v1.resampler(x,sig.Fs,obj.newFs, sig.Rs)); %#ok<*EMFH>
                case 'matlab'
                    sig = sig.fun1(@(x)resample(x,obj.newFs,sig.Fs));
                case 'spline'
                    sig = sig.fun1(@(x)Resample_v1.splineResampler(x,sig.Fs,obj.newFs)); %#ok<*EMFH>
            end
            out = set(sig,'Fs',obj.newFs);
%             out = signal_interface(sig.get, struct('Rs', sig.Rs, 'Fs', obj.newFs, 'Fc', sig.Fc, 'P', sig.P));
        end
        
    end
    
    methods (Static)
        %> @brief Resample using Gardner
        %>
        %> Resamples signal using clock phase as determined by the Gardner
        %> timing error detector.  This is calculated by averaging over the
        %> first 10^4 samples, so if there is clock skew, it will be
        %> incorrect at the end of the signal.  Interpolation is performed
        %> using a cubic spline.
        %>
        %> @param in input signal
        %> @param Fs sampling frequency of input signal
        %> @param Fs_new sampling frequency of output signal
        %> @param Fb symbol rate
        %>
        %> @retval out resampled output
        %> @retval PD_gardner error detector output
        function [out, PD_gardner] = resampler(in, Fs, Fs_new, Fb)
            
            % dt_rec = param_rx.Fs/(2*param_rx.baudrate);
            dt_rec = Fs/Fs_new;
            nom_v = round(Fs/Fb); %FIXME why round?
            
            L_max = min(1000, length(in));
            t_new = 1:dt_rec:length(in);
            t_new = t_new(1:end-L_max);
            
            step = 0.03;
            var = linspace(0,1,1/step);
            var = var(1:end-1);
            % PD_gardner = inf(size(var));
            
            L = min(10e3, length(in));
            
            PD_gardner = Resample_v1.FindRes(var,nom_v,in,t_new,L);
            % PD_gardner = FindRes_mex(var,nom_v,in,t_new,L);
            
            % for a_c = 1:length(var)
            %     Toff = var(a_c)*nom_v;
            % %     I = interp1(real(in),t_new+Toff,'spline');
            %     I = interp1(real(in),t_new+Toff,'linear');
            %     PD_gardner(a_c) = mean( I(2:2:L-1) .* (I(3:2:L)-I(1:2:L-2)) );
            % end
            
            [~,PD_min] = min( abs(PD_gardner).^2 );
            Toff = var(PD_min)*nom_v;
            out = interp1(in,t_new+Toff,'spline',0);
            out = out(:);
        end
        
        %> @brief Gardner error detector
        %>
        %> Calculates Gardner error term for signal
        %>
        %> @param var test timing offsets to try
        %> @param nom_v approximate number of samples per symbol
        %> @param in input signal
        %> @param t_new vector of time to interpolate to (?)
        %> @param L length of signal to consider
        %>
        %> @retval PD_gardner error detector output
        function PD_gardner = FindRes(var,nom_v,in,t_new,L)
            
            %#codegen
            PD_gardner = inf(size(var));
            %
            % N = numel(var);
            % idx = (1:length(in))';
            % t_old = repmat(idx,[1 N]);
            % Toff = var*nom_v;
            % t_new2 = bsxfun(@plus,t_new',Toff);
            %
            % I = interp1(t_old,repmat(in,[1 N]),t_new2,'linear');
            % PD_gardner = (I(2:2:L-1,:).* (I(3:2:L,:)-I(1:2:L-2,:)) );
            
            y = real(in(1:L));
            x = 1:L;
            
            t_new = t_new(1:L);
            
            for a_c = 1:length(var)
                Toff = var(a_c)*nom_v;
                %     I = interp1(1:length(in),real(in),t_new+Toff,'linear');
                I = interp1(x,y,t_new+Toff,'linear');
                %     I = qinterp1(1:length(real(in)),real(in),t_new+Toff,1);
                PD_gardner(a_c) = mean( I(2:2:L-1) .* (I(3:2:L)-I(1:2:L-2)) );
            end
            
        end
        
        function [out] = splineResampler(in, Fs, Fs_new)
            
            % dt_rec = param_rx.Fs/(2*param_rx.baudrate);
            dt_in = 0:1/Fs:((length(in)-1)/Fs);
            dt_out = 0:1/Fs_new:dt_in(end);
           
            out = interp1(dt_in, in(:).', dt_out,'spline',0);
            out = out(:);
        end
    end
end
