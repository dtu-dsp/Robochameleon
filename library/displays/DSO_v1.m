%> @file DSO_v1.m
%> @brief Digital storage oscilloscope
%>
%> @class DSO_v1
%> @brief Digital storage oscilloscope
%>
%> 
%> It shows what's going on in your signal(s). Adapts to the number of
%> channels to show constellations or just eye diagrams.  Requires a
%> modulated signal with integer number of samples per symbol.
%>
%> Learns most information from the signal - it is best to not pass
%> parameters yourself.
%>
%> While debugging, you can call the static method
%> DSO_v1.plot(signal_interface object) or DSO_v1.plotSignal(y, Nss, Fs)
%> to see how your signal looks.
%>
%> @author Miguel Iglesias Olmedo
%> @version 1
classdef DSO_v1 < unit
    
    properties (Hidden)
        %> Number of inputs
        nInputs;
        %> Number of outputs
        nOutputs=0;
        %> operating mode
        mode;       % 'single' to treat each channel as a PAM signal
                    % 'coherent' to group 2 channels and treat it as a QAM 
        %> upper limit on number of samples (to speed up)
        maxlength;  
        %> Enables or disables the display {1|0}
        enable;     % {1|0}, enables or disables the output.
        only;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> @param param.nInputs	Number of inputs [Default: 1];
        %> @param param.mode	How to treat different channels {'single' -as PAM| 'coherent' as separated I and Q} [Default: single]
        %> @param param.maxlength   Maximum number of points to plot [Default: all]
        %> @param param.enable   Plot/don't plot (for loops). [Default: on]
        %>
        %> @retval obj      An instance of the class DSO_v1
        function obj = DSO_v1(param)
            if ~exist('param', 'var')
                param={};
            end
            obj.nInputs = paramdefault(param,'nInputs',1);
            obj.mode = paramdefault(param, 'mode', 'single');
            obj.maxlength = paramdefault(param, 'maxlength', 0);
            obj.only = paramdefault(param,'only',[]);
            obj.enable = paramdefault(param, 'enable', 1);
        end
        
        %> @brief Gathers information about signal, plots
        %>
        %> @param in    The signal_interface to plot
        function traverse(obj,varargin)
            if (obj.enable)
                if strcmp(obj.mode,'coherent') && length(varargin) == 4
                    sig = Combiner_v1.combine(varargin);
                    sig = Combiner_v1.combineComplex(sig);
                    obj.plot(sig, obj.maxlength, obj.only);
                else
                    for i=1:obj.nInputs
                        if strcmp(obj.mode,'coherent')
                            sig = Combiner_v1.combineComplex(varargin{i});
                            obj.plot(sig, obj.maxlength, obj.only);
                        else
                            obj.plot(varargin{i}, obj.maxlength, obj.only);
                        end
                    end
                end
            end
        end
    end
    
    methods (Static)
        
        %> @brief Main plotting function
        %>
        %>
        %> @param varargin    [The signal_interface to plot, maxlength, channels]
        function plot(varargin)
            sig = varargin{1};
            if ~iswhole(sig.Nss)
                robolog(['Number of samples per symbol is not'...
                    'integer. Resample to a new Fs of '...
                    num2str(sig.Rs*ceil(sig.Nss)*1e-9)...
                    ' GHz if you want to see something' ],'WRN');
            end
            x = sig.get;
            if nargin  == 2 && varargin{2} > 10
                maxlen = min(varargin{2}, length(x));
                x = x(1:maxlen, :);
            end
            only=[];
            if nargin == 3
                only = varargin{3};
            end
            if isempty(only)
                only = 1:sig.N;
            end
            ch = intersect(1:sig.N, only);
            for i=ch
                if ~isempty(x(:,i)) && any(x(:,i))
                    h = figure('Name',['DSO channel ' num2str(i)]);
                    DSO_v1.plotSignalFig(x(:,i) ,sig.Nss,sig.Fs, h)
                else
                    robolog(['Signal in colulmn ' num2str(i) ' is empty'],'WRN')
                end
            end
        end
        
        function plotSignal(y, Nss, Fs)
            h = figure('Name','DSO');
            plotSignalFig(y, Nss, Fs, h)
        end
        
        function plotSignalFig(y, Nss, Fs, h)
            flags = DSO_v1.initPlot(h, y, Nss);
            rows = flags.size(1);
            cols = flags.size(2);
            if flags.decimate
                [srx,idx] = Decimate_v1.decimate(y, Nss);
            elseif Nss == 1
                srx = y;
            end
            if flags.spectrum
                subplot(rows, cols, flags.spectrum)
                DSO_v1.plotSpectrum(y,Nss,Fs)
                set(gca, 'LooseInset', get(gca, 'TightInset'));
            end
            if flags.constellation
                subplot(rows, cols, flags.constellation)
                DSO_v1.plotConstellation(srx)
                set(gca, 'LooseInset', get(gca, 'TightInset'));
            end
            if flags.eyeI
                subplot(rows, cols, flags.eyeI)
                DSO_v1.plotEye(real(y),Nss,Fs)
%                 gridxy((Nss+idx-1)/Fs*1e12, [], 'LineStyle', '--', 'color', [1 1 1]./1.5)
            end
            if flags.eyeQ
                subplot(rows, cols, flags.eyeQ)
                DSO_v1.plotEye(imag(y),Nss,Fs)
%                 gridxy((Nss+idx-1)/Fs*1e12, [], 'LineStyle', '--', 'color', [1 1 1]./1.5)
            end
            if flags.timeI
                ht(1) = subplot(rows, cols, flags.timeI);
                DSO_v1.plotTimeSignal(real(y),Nss)
                set(gca, 'LooseInset', get(gca, 'TightInset'));
            end
            if flags.timeQ
                ht(2) = subplot(rows, cols, flags.timeQ);
                DSO_v1.plotTimeSignal(imag(y),Nss)
                set(gca, 'LooseInset', get(gca, 'TightInset'));
            end
            if length(ht) > 1
                linkaxes(ht);
            end
        end
        function flags = initPlot(h, y, Nss)
            set(h, 'Units', 'pixels')
            flags = {};
            if Nss == 1 && isreal(y)
                ratioW = 0.3;
                ratioH = 0.8;
                flags.decimate = 0;
                flags.size = [1 1];
                flags.spectrum = 0;
                flags.constellation = false;
                flags.eyeI = false;
                flags.eyeQ = false;
                flags.timeI = 1;
                flags.timeQ = false;
            elseif Nss == 1 && ~isreal(y)
                ratioW = 0.3;
                ratioH = 0.8;
                flags.decimate = 0;
                flags.size = [4 1];
                flags.spectrum = 0;
                flags.constellation = [1 2];
                flags.eyeI = false;
                flags.eyeQ = false;
                flags.timeI = 3;
                flags.timeQ = 4;
            elseif iswhole(Nss) && isreal(y)
                ratioW = 0.4;
                ratioH = 0.8;
                flags.decimate = 1;
                flags.size = [3 1];
                flags.spectrum = 1;
                flags.constellation = false;
                flags.eyeI = 2;
                flags.eyeQ = false;
                flags.timeI = 3;
                flags.timeQ = false;
            elseif iswhole(Nss) && ~isreal(y)
                ratioW = 0.4;
                ratioH = 0.8;
                flags.decimate = 1;
                flags.size = [4 3];
                flags.spectrum = [1 2 3];
                flags.constellation = 5;
                flags.eyeI = 4;
                flags.eyeQ = 6;
                flags.timeI = [7  8  9 ];
                flags.timeQ = [10 11 12];
            elseif ~iswhole(Nss) && isreal(y)
                ratioW = 0.4;
                ratioH = 0.8;
                flags.decimate = 0;
                flags.size = [2 1];
                flags.spectrum = 1;
                flags.constellation = false;
                flags.eyeI = false;
                flags.eyeQ = false;
                flags.timeI = 2;
                flags.timeQ = false;
            elseif ~iswhole(Nss) && ~isreal(y)
                ratioW = 0.4;
                ratioH = 0.8;
                flags.decimate = 0;
                flags.size = [3 1];
                flags.spectrum = 1;
                flags.constellation = false;
                flags.eyeI = false;
                flags.eyeQ = false;
                flags.timeI = 2;
                flags.timeQ = 3;
            end
            scrsz = get(0,'ScreenSize');
            %set(gcf,'Position',[scrsz(3)/2 scrsz(4)/2-200 width*50 height*50])
            set(h,'OuterPosition',[1 scrsz(4)*(1-ratioH) scrsz(3)*ratioW scrsz(4)*ratioH ])
        end
        
        function plotSpectrum(y, Nss, Fs)
            colors;
            [ f, spectrum ] = spectra(y, Fs, 0);
            s = 10*log10(spectrum.*conj(spectrum)*1e3);
            sm = smooth(s,length(s)/100);
            adj = max(s)-max(sm);
            BW = find(sm>max(sm(10:end))-3);
            if isempty(BW)
                BW = 0;
            else
                BW = f(BW(end));
            end
            patchline(f*1e-9, s, 'edgecolor', blue, 'edgealpha',0.05 )
            hold on
            plot(f*1e-9, sm, 'color', red, 'LineWidth',2)
            gridxy(BW*1e-9, (max(sm)-3), 'LineStyle', '--', 'color', [1 1 1]./1.5)
            hold off
            ylim([mean(s) max(s(100:end))])
            xlim([0 Fs/2*1e-9])
            grid on
            ylabel('dBm')
            xlabel('GHz')
            title(['Rs = ' num2str(Fs/Nss*1e-9, '%.0f') ' Gbaud | Fs = '  num2str(Fs*1e-9, '%.0f') ' GSa/s | BW = ' num2str(BW*1e-9, '%.2f') ' GHz' ])
        end
        
        function plotEye(varargin)
            y = varargin{1};
            Nss = varargin{2};
            Fs = varargin{3};
            if nargin > 3
                NumberOfEyes = varargin{4};
            else
            NumberOfEyes = 3;
            end
            colors;
            nsymb = floor(length(y)/Nss);
            NumberOfStoredTraces=2^10;
            if floor(nsymb/NumberOfEyes) < NumberOfStoredTraces
                NumberOfStoredTraces = floor(nsymb/NumberOfEyes);
            end
            y_eye=y(1:Nss*NumberOfEyes*NumberOfStoredTraces);
            y_eyeI = reshape(real(y_eye),Nss*NumberOfEyes,length(y_eye)/Nss/NumberOfEyes);
            t_eye=(0:(Nss*NumberOfEyes-1))/Fs*1e12;
            for e=1:size(y_eyeI,2)
                patchline(t_eye, y_eyeI(:,e), 'edgecolor', blue, 'edgealpha',0.1,'linewidth',1 )
            end
%             plot(t_eye, y_eyeI, 'color', blue, 'linewidth',5)
            hold on
            
            y_opt = var(y_eyeI,0,2);
            [~, idx] =  max(y_opt);
            y_optPlot = (y_opt-mean(y_opt));
            y_optPlot = y_optPlot/max(y_optPlot)*std(y_eye);
            y_optPlot = y_optPlot + mean(y_eye);
            gridxy((idx-1)/Fs*1e12, [], 'LineStyle', '--', 'color', [1 1 1]./1.5)

            plot(t_eye, y_optPlot, '--', 'color', red)
            xlabel('Time (ps)')
            ylabel('a.u.')
            ylim(DSO_v1.ylim_time(y))
            xlim([0 t_eye(end)])
        end
        function plotConstellation(varargin)
            srx = double(varargin{1});
            colors;
            scatplot(real(srx),imag(srx),'voronoi');
%             plot(srx, '.', 'color', blue, 'MarkerSize',3);
            hold on
            if nargin >1
                % Plot clusters centroids
                c = varargin{2};
                plot(c,  'o', 'color', red, 'MarkerFaceColor', red, 'MarkerSize',3)
            end
            xlim(1.1*[min(real(srx)) max(real(srx))])
            ylim(1.1*[min(imag(srx)) max(imag(srx))])
        end
        
        function plotTimeSignal(y, Nss)
            colors;
            if Nss == 1
                plot(y,'-o','color', blue,'MarkerFaceColor',blue,'MarkerSize',2)
                xlabel('Symbols')
            else
                plot(y,'color', blue)
                xlabel('Samples')
            end
            ylim(DSO_v1.ylim_time(y))
            xlim([1 length(y)])
            ylabel('a.u.')
        end
        function ylim_time = ylim_time(y)
            ylim_time = 1.1*[min(real(y)) max(real(y))];
        end
    end
end

