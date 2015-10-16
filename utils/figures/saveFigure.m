function  saveFigure( filename, papersize, guardar )
%SAVEFIGURE Summary of this function goes here
%   Detailed explanation goes here

    scrsz = get(0,'ScreenSize');
    set(gcf,'Position',[scrsz(3)/2 scrsz(4)/2-200 papersize(1)*50 papersize(2)*50])
    set(gca, 'LooseInset', get(gca, 'TightInset'));
if (guardar)
    exportfig(gcf, [filename '.eps'], 'width',papersize(1), 'height', papersize(2),'fontmode','fixed', 'fontsize', 8, 'color', 'cmyk'); 
end
end

