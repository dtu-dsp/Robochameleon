%> @file plotSignal.m
%> @brief Plot signal using options based on signal properties
%>
%> Depending on what is possible, this function will plot any of the
%> following quantities:
%>
%> 1. Time-domain trace
%>
%> 2. Constellation
%>
%> 3. Power spectrum
%>
%> 4. Eye diagrams
%> 
%> @author Miguel Iglesias Olmedo
%>
%> @see pabs.m, pabsang.m, pabsh.m, pconst.m, preim.m
%>
%> @version 1

%> @brief Plot signal_interface using options based on signal properties
%>
%> @param y          Waveform
%> @param Nss        Number of samples per symbol
%> @param Fs         Sampling frequency [Hz]
function plotSignal(y,Nss,Fs)
colors

if (Nss>1)
    %% Processing
    % Obtain data and plot limits
    y=y(:);
    ylim_time = 20*[-var(y) var(y)] + mean(y);
    ylim_time = 1.1*[min(y) max(y)];
    % Calculate sampling point
    srx = y(1:end-rem(length(y),Nss));
    y_opt = zeros(1,Nss);
    for k=1:Nss
        y_opt(k) = sum( abs( srx(k:Nss:end) ).^2);
    end
    [nul,idx] = max(y_opt);
    % Get the symbols
    srx = srx(idx:Nss:end);
    srx = srx(:).'*modnorm(srx, 'avpow' ,1);
    
    %% Initialize plot
    figure
    set(gcf, 'Units', 'pixels')
    if isreal(y)
        ratioW = 0.4;
        ratioH = 0.8;
    else
        ratioW = 0.4;
        ratioH = 0.9;
    end
    scrsz = get(0,'ScreenSize');
    %set(gcf,'Position',[scrsz(3)/2 scrsz(4)/2-200 width*50 height*50])
    set(gcf,'OuterPosition',[1 scrsz(4)*(1-ratioH) scrsz(3)*ratioW scrsz(4)*ratioH ])
    
    %% Plot spectrum
    if isreal(y)
        subplot(3,1,1)
    else
        subplot(4,3,[1 2 3])
    end
    [ f, spectrum ] = spectra(y, Fs, 0);
    s = 10*log10(spectrum.*conj(spectrum)*1e3);
    sm = smooth(s,length(s)/100);
    adj = max(s)-max(sm);
    BW = find(sm>max(sm(10:end))-3);
    BW = f(BW(end));
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
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    
    %% Plot Eyes
    % Cropping
    nsymb = length(y)/Nss;
    NumberOfStoredTraces=2^11;
    NumberOfEyes = 2;
    if (nsymb < NumberOfStoredTraces)
        NumberOfStoredTraces = nsymb;
    end
    y_eye=y(1:Nss*NumberOfStoredTraces);
    if isreal(y)
        subplot(3,1,2)
    else
        heye(1) = subplot(4,3,4);
        title('I')
    end
    y_eyeI = reshape(real(y_eye),Nss*NumberOfEyes,length(y_eye)/Nss/NumberOfEyes);
    t_eye=(0:(Nss*NumberOfEyes-1))/Fs*1e12;
    for e=1:size(y_eyeI,2)
        patchline(t_eye, y_eyeI(:,e), 'edgecolor', blue, 'edgealpha',0.1 )
    end
    hold on
    hold on
    y_optPlot = (y_opt-mean(y_opt));
    y_optPlot = y_optPlot/max(y_optPlot)*std(y_eye);
    y_optPlot = y_optPlot + mean(y_eye);
    y_optPlot = repmat(y_optPlot(:),NumberOfEyes,1);
    plot(t_eye, y_optPlot, '--', 'color', red)
    gridxy((Nss+idx-1)/Fs*1e12, [], 'LineStyle', '--', 'color', [1 1 1]./1.5)
    xlabel('Time (ps)')
    ylabel('a.u.')
    ylim(ylim_time)
    xlim([0 t_eye(end)])
    
    if ~isreal(y)
        heye(2) = subplot(4,3,6);
        title('Q')
        y_eyeQ = reshape(imag(y_eye),Nss*NumberOfEyes,length(y_eye)/Nss/NumberOfEyes);
        for e=1:size(y_eyeQ,2)
            patchline(t_eye, y_eyeQ(:,e), 'edgecolor', blue, 'edgealpha',0.1 )
        end
        hold on
        gridxy((Nss+idx-1)/Fs*1e12, [], 'LineStyle', '--', 'color', [1 1 1]./1.5)
        ylim([-1 1])
        xlim([0 t_eye(end)])
        xlabel('Time (ps)')
        linkaxes(heye, 'x');
    end
    
    %% Plot constellation
    if ~isreal(y)
        subplot(4,3,5);
        plot(real(srx), imag(srx), '.', 'color', blue, 'MarkerSize',3);
        hold on
        % Plot clusters centroids
        xlim([-1.5 1.5])
        ylim([-1.5 1.5])
        set(gca, 'LooseInset', get(gca, 'TightInset'));
    end
    
    %% Plot time domain signals
    if isreal(y)
        subplot(3,1,3)
        plot(real(y),'color', blue);
        ylabel('a.u.')
        xlabel('Samples')
        ylim(ylim_time)
        xlim([1 length(y)])
    else
        htime(1) = subplot(4,3,[7 8 9]);
        plot(real(y),'color', blue)
        ylabel('a.u.')
        xlabel('Samples')
        ylim([-1 1])
        xlim([1 length(y)])
        
        htime(2) = subplot(4,3,[10 11 12]);
        plot(imag(y),'color', blue)
        ylabel('a.u.')
        xlabel('Samples')
        ylim(ylim_time)
        xlim([1 length(y)])
        linkaxes(htime, 'x');
    end
elseif Nss==1
    srx = y(:).'*modnorm(y, 'avpow' ,1);
    %% Initialize plot
    figure
    set(gcf, 'Units', 'pixels')
    if isreal(y)
        ratioW = 0.6;
        ratioH = 0.4;
    else
        ratioW = 0.6;
        ratioH = 0.4;
    end
    scrsz = get(0,'ScreenSize');
    %set(gcf,'Position',[scrsz(3)/2 scrsz(4)/2-200 width*50 height*50])
    set(gcf,'OuterPosition',[1 scrsz(4)*(1-ratioH) scrsz(3)*ratioW scrsz(4)*ratioH ])
    
    %% plot Constellation
    if ~isreal(y)
        subplot(2,2,[1 3])
        plot(real(srx), imag(srx), '.', 'color', blue, 'MarkerSize',4);
    end
    
    %% plot Time signals
    if isreal(y)
        plot(srx,'color', blue)
    else
        subplot(2,2,2)
        plot(real(srx),'color', blue)
        ylim(ylim_time)
        xlim([1 length(srx)])
        ylabel('a.u.')
        subplot(2,2,4)
        plot(real(srx),'color', blue)
        ylim(ylim_time)
        xlim([1 length(srx)])
        ylabel('a.u.')
        xlabel('Samples')
    end
else
    disp('Wrong Nss')
end
end