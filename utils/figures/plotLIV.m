function plotLIV( current,voltage,power_dB, Ibias, Vpp )

colors
arrowColor =  [1 1 1]./2.5;
% power to natural units
power_mW = 10.^(power_dB./10);
% Vpp, Ipp and ER calculations
[nul pos] =min(abs(current-Ibias));
Vbias=voltage(pos);
Vextremes = [Vbias-Vpp/2 Vbias+Vpp/2];
[nul pos1] =min(abs(voltage-Vextremes(1)));
[nul pos2] =min(abs(voltage-Vextremes(2)));
Iextremes = [current(pos1) current(pos2)];
Pextremes = [power_mW(pos1) power_mW(pos2)];
Pbias = power_mW(pos);
Ipp=diff(Iextremes);
ER = 10*log10(Pextremes(2)/Pextremes(1));

% Plotting
figure
[AX,H1,H2] = plotyy(current,power_mW,current,voltage, 'plot');
hold on
stem(Ibias,Pbias,'LineStyle', '--', 'color', [1 1 1]./1.6, 'MarkerFace', blue, 'MarkerEdge', blue)
gridxy(Iextremes,[] , 'LineStyle', '--', 'color', blue)

arrow([Iextremes(1) Pextremes(1)], [Iextremes(2) Pextremes(1)], 'Ends', 'both','EdgeColor', arrowColor, 'FaceColor', arrowColor)
arrow([Iextremes(2) Pextremes(1)], [Iextremes(2) Pextremes(2)], 'Ends', 'both','EdgeColor', arrowColor, 'FaceColor', arrowColor)

text(Ibias,Pbias,'Bias point', 'VerticalAlignment', 'bottom','HorizontalAlignment', 'right')
text(Ibias,Pextremes(1), [num2str(Vpp,3) ' Vpp'], 'VerticalAlignment', 'bottom','HorizontalAlignment', 'center')
text(Iextremes(2),mean(Pextremes), ['ER = ' num2str(ER,3) ' dB'], 'VerticalAlignment', 'bottom','HorizontalAlignment', 'center', 'rotation', 90)

set(get(AX(1),'Xlabel'),'String','Current (mA)')
set(get(AX(1),'Ylabel'),'String','Optical power (mW)','Color', blue)
set(AX(1),'YColor', blue)
set(AX(2),'YColor', red)
set(get(AX(2),'Ylabel'),'String','Voltage (V)', 'color', red)
set(H1,'LineStyle','-',  'color', blue, 'LineWidth', linewidth)
set(H2,'LineStyle','-.',  'color', red_soft, 'LineWidth', linewidth)

end

