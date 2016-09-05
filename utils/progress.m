%> @file progress.m
%> @brief display progress on command line
%>
%> This function displays the progress as a percentage in command line
%> overwritting itself. It only updates when the percentage is changed, so
%> that time penalty is kept to around 4% of the simulation time. 
%>
%> __Example__
%> 
%> @code
%> robolog('Processing L samples')
%> for i=1:L
%>    progress(i,L)
%> end
%> @endcode
%> 
%> @version 1
%> 
%> @author Miguel Iglesias Olmedo - miguelio@kth.se
%> 
%> @brief Search for the traces matching the parameters in the input structure
%>
%> @param i index
%> @param L total
function progress(i,L)
perc=i/L*100;
percFix=fix(perc);
if i==1
    fprintf(1, '\b...    ')
elseif abs(perc-percFix)<1e-3
    fprintf(1,'\b\b\b\b%3d%%',percFix);
end
if i == L
    disp(' ')
end
end