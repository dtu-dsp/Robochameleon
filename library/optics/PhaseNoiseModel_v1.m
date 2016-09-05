%> @file PhaseNoiseModel_v1.m
%> @brief helper class for phase noise modeling
%>
%> @class PhaseNoiseModel_v1
%> @brief helper class for phase noise modeling
%> 
%> This is a helper class that is useful for phase noise stuff. It can
%> calculate phase and frequency noise spectral densities as well as
%> the optical lineshape
%>
%> 
%> @see Laser_v1
%> @author Miguel Iglesias Olmedo
%> @version 1
classdef PhaseNoiseModel_v1

    
    properties (SetAccess=public)
        % Plotting properties
        %> For the 3 dB linewidth plot
        zoom;       
        
        % Signal dependent properties
        %> Length of the frequency psd
        Lpsd;
        %> Length of the optical lineshape
        Llw;          
        MinFreq;
        MaxFreq;
        %> {'linear' | 'log'}. For plotting the lineshape you need log.
        type;         
        
        %> Lorentzian phase noise: 3dB linewidth
        linewidth;
        
        % Semiconductor type phase noise properties
        %> SCL phase noise: low frequency linewidth at 1 GHz
        LFLW1GHZ;   
        %> SCL phase noise: high frequency linewidth
        HFLW;       
        %> SCL phase noise: resonance frequency
        fr; 
        %> SCL phase noise: width of the resonance peak
        K;
        %> SCL phase noise: quantum limit (gaussian noise floor)
        alpha;   	
        %> SCL phase noise: quantum limit (gaussian noise floor)
        f_cutoff;
        
    end
    
    methods
        
        function obj = PhaseNoiseModel_v1(param)
            %Intialize parameters
            obj.Lpsd = paramdefault(param, 'Lpsd', 2^10);
            obj.Llw = paramdefault(param, 'Llw', 2^14);
            obj.MinFreq = paramdefault(param, 'MinFreq', 1e3);
            obj.MaxFreq = paramdefault(param, 'MaxFreq', 50e9);
            obj.type = paramdefault(param, 'type', 'log');
            obj.f_cutoff =  paramdefault(param, 'f_cutoff', 0);
            % If linewidth is specified, lorenztial lineshape is assumed.
            if isfield(param, 'linewidth') && ~isempty(param.linewidth)
                obj.linewidth = param.linewidth;
                obj.zoom = paramdefault(param, 'zoom', 2*obj.linewidth);
            else
                obj.LFLW1GHZ=param.LFLW1GHZ;
                obj.HFLW=param.HFLW;
                obj.fr=param.fr;
                obj.K=param.K;
                obj.alpha=param.alpha;
                if obj.LFLW1GHZ > 50
                    obj.zoom = paramdefault(param, 'zoom', 1e5*sqrt(obj.LFLW1GHZ));
                else
                    obj.zoom = paramdefault(param, 'zoom', 2*obj.HFLW);
                end
            end
        end
        
        % Generates the frequency axis
        function FMfreq = FMfreq(obj)
            switch obj.type
                case 'linear'
                    FMfreq=linspace(obj.MinFreq,obj.MaxFreq,obj.Lpsd)';
                case 'log'
                    FMfreq = logspace(log10(obj.MinFreq),log10(obj.MaxFreq),obj.Lpsd)';
            end
        end
        
        % Generates the Frequency and Phase power spectral densities
        function [FMnoiseCal, PMnoiseCal] = genPSD(obj)
            % Build FMnoiseCal
            FMfreq = obj.FMfreq();
            if ~isempty(obj.linewidth)
                FMnoiseCal = obj.linewidth/pi*ones(size(FMfreq));
            else
                FMnoiseCal=obj.PSDmodel(obj.FMfreq,obj.LFLW1GHZ,obj.HFLW,obj.K,obj.fr,obj.alpha);
            end
            if obj.f_cutoff ~= 0 && obj.f_cutoff>=obj.MinFreq
                for a=1:length(FMfreq)
                    if(FMfreq(a)<obj.f_cutoff)
                        FMnoiseCal(a)=0;
                    end
                end
            end
            PMnoiseCal = (2*pi)^2*FMnoiseCal./((2*pi)^2*FMfreq.^2);
        end
        % Generates the Frequency Power Spectral Density
        function FMnoiseCal = genFMPSD(obj)
            [FMnoiseCal, ~] = genPSD(obj);
        end
        % Generates the Frequency Power Spectral Density
        function PMnoiseCal = genPNPSD(obj)
            [~, PMnoiseCal] = genPSD(obj);
        end
        % Spectral Lineshape Calculators
        function [SPEC,F] = getLineShape(obj, fmax)
            NoLWPts = obj.Llw;
            [SPEC,F]=obj.CalcSpectrum(obj.genPSD,obj.FMfreq,NoLWPts,fmax/2);
        end
        
        function lw = getLinewidth(obj, point)
            [SPEC,F] = getLineShape(obj, 15e6);
            line = repmat(point, [length(SPEC), 1]);
            intersects = intersections(F,line,F,pow2db(SPEC/max(SPEC)));
            lw = max(diff(intersects));
        end
        %% Plotting functions
        function plotLineShape(obj, varargin)
            plotZoom =true;
            if nargin > 1
                plotZoom = varargin{1};
            end
            colors
            % Get frequency limits for lineshape and inner plot
            fmax1 = 15e9;
            if obj.linewidth
                fmax2=2*obj.linewidth;
            elseif obj.LFLW1GHZ
                fmax2 = 1.1e6*sqrt(obj.LFLW1GHZ);
            else
                fmax2 = 3*obj.HFLW;
            end
            % Calculate & plot lineshape
            [SPEC,F] = getLineShape(obj,fmax1);
            SPEC = SPEC/max(SPEC);
            plot(F*1e-9,pow2db(SPEC), 'color', red);
            xlim(fmax1*[-1 1]*1e-9)
            ylim([-100 0])
            ylabel('dB')
            xlabel('GHz')
            title('Optical lineshape')
            hold on
            if plotZoom
                % Calculate lineshape of the zoom
                [SPEC,F] = getLineShape(obj,fmax2);
                SPEC = SPEC/max(SPEC);
                point = -3;
                line = repmat(point, [length(SPEC), 1]);
                intersects = intersections(F,line,F,pow2db(SPEC));
                lw = max(diff(intersects));
                
                
                handaxes2 = axes('Position', [0.18 0.66 0.1 0.2]);
                if isempty(obj.zoom)
                    obj.zoom = 2*lw;
                end
                [~, Zoom, axFactor, axUnit] = formatPrefixSI(obj.zoom,'','Hz');
                plot(F*axFactor,pow2db(SPEC), 'color', red);
                hold on
                plot([intersects(1) intersects(end)]*axFactor,[point point], 'ko', 'MarkerFaceColor', 'k');
                [~, lw, ~, lwUnit] = formatPrefixSI(lw,'','Hz');
                title([num2str(lw,3), [' ' lwUnit]])
                ylim([-5 0])
                xlim(Zoom*[-1 1])
                set(handaxes2, 'Box', 'off')
                ylabel('dB')
                xlabel(axUnit)
                box on
            end
            %             hold on
            %             [SPEC,F]=Laser_v2.CalcSpectrum2(obj.FMnoiseCal,obj.FMfreq,NoLWPts,fmax);
            %             plot(F,pow2db(SPEC/max(SPEC)), 'r');
        end
        
        function plotFMPSD(obj,varargin)
            % Plot FREQUENCY PSDs
            if nargin >1
                loglog(obj.FMfreq, pi*obj.genFMPSD(),varargin)
            else
                colors
                loglog(obj.FMfreq, pi*obj.genFMPSD(),  'color', red, 'LineWidth',2)
            end
            %             y = obj.FMnoiseCal.*(sinc(obj.FMfreq/obj.Rs).^2);
            %             loglog(obj.FMfreq, pi*y, 'r:','LineWidth',2)
            %             xlim([obj.MinFreq, obj.MaxFreq])
            xlim([obj.MinFreq, 100e9])
            ylim([1e4 1e8])
            %             if ~isnan(obj.fn)
            %                 ylim(1.1*pi*[min(FN) max(FN)]);
            %             end
            title('\pi S_{\nu}(f)')
            xlabel('Hz')
            ylabel('Hz^2 / Hz');
            grid on
        end
        
        function plotPNPSD(obj,varargin)
            % Plot phase PSDs
            if nargin >1
                loglog(obj.FMfreq, obj.genPNPSD(),varargin)
            else
                colors
                loglog(obj.FMfreq, obj.genPNPSD(),  'color', red, 'LineWidth',2)
            end
            try
                xlim([obj.MinFreq, obj.MaxFreq])
            catch
            end
            title('\pi S_{\phi}(f)')
            xlabel('Hz')
            ylabel('Hz^2 / Hz');
            grid on
        end
        
        function plot(obj)
            width = 1080;
            figure('Position', [100, 100, width, width*3/8])
            subplot(1,2,1)
            obj.plotLineShape
            subplot(1,2,2)
            obj.plotFMPSD
        end
    end
    
    
    %% Static methods
    methods (Static)
        function FMnoise = PSDmodel(FMfreq,LFLW1GHZ,HFLW,K,fr,alpha)
            FMnoise=LFLW1GHZ/pi*1e9./FMfreq;
            FMnoise=FMnoise+HFLW/pi*(1/(1+alpha^2));
            FMnoise=FMnoise+HFLW/pi*(alpha^2/(1+alpha^2))...
                *fr^4./((fr^2-FMfreq.^2).^2+(K/2/pi)^2*fr^4*FMfreq.^2);
        end
        function phaseModel = fitModel(f,y)
            ft = fittype( 'PhaseNoiseModel_v1.PSDmodel(FMfreq,LFLW1GHZ,HFLW,K,fr,alpha)' );
            
        end
        function[SPEC,F]=CalcSpectrum2(FMnoise,freq,NoLWPts,fmax)
            %             akf = autocorr(FMnoise, NoLWPts);
            df = fmax/NoLWPts;
            for i=1:NoLWPts
                tau=(i-1)/df;
                akf(i) = exp(-2*(pi*tau)^2*trapz(freq,FMnoise.*sinc(pi*freq*tau).^2));
                %                F(i) = (i-1)*df;
            end
            SPEC = abs(fftshift(fft(akf)));
            F = linspace(-fmax,fmax,NoLWPts);
        end
        function[SPEC,F]=CalcSpectrum(FMnoise,freq,NoLWPts,fmax)
            %             FMnoise=db2pow(FMnoise);
            df= 2*2*fmax/NoLWPts;
            taumax=1/(2*df);
            AKF=zeros(NoLWPts/2+1,1);
            F=zeros(NoLWPts/2+1,1);
            TAU=zeros(NoLWPts/2+1,1);
            dtau=2*taumax/NoLWPts;
            for i=1:NoLWPts/2
                tau = taumax-(i-1)*dtau;
                AKF(i)=exp(-pi*tau*PhaseNoiseModel_v1.EffLinewidth(1/tau, FMnoise, freq));
                TAU(i)=-tau;
                F(i)=(i-1)*df;
                %if not(round(tau-0.5)==round(tau-0.5-dtau))
                % round(tau);
                %end;
            end;
            AKF(NoLWPts/2+1)=1;
            Tau(NoLWPts/2+1)=0;
            F(NoLWPts/2+1)=NoLWPts/2*df;
            AKF=[AKF;AKF(end-1:-1:1)];
            TAU=[TAU;-TAU(end-1:-1:1)];
            SPEC=abs(fftshift(fft(AKF)));
            F=[-flipud(F);F(2:end)];
        end
        
        function EffLW = EffLinewidth(BaudRate, FMnoise, freq)
            x = freq;
            tau=1/BaudRate;
            y = FMnoise.*(sinc(freq*tau).^2);
            EffLW=2*(pi*tau)*trapz(x,y);
        end
    end
end