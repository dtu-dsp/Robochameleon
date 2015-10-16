function screen( rows, columns, row, column )
%SCREEN sets the current figure into a certain possition. The screen is
%divided by the number of @rows and @column, and the figure is possition in
% @row and @column.

    scrsz = get(0,'ScreenSize');
    height=scrsz(4);
    width=scrsz(3);

    x = width/columns*(column-1);
    y = height - height/rows*(row);
    w = width/columns;
    h = height/rows;
    set(gcf, 'Position', [x y w h])
    
end

