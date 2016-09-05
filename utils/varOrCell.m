%> @file varOrCell.m
%> @brief Returns variable or specified element of cell array
%>
%> @ingroup {utils}
%>
%> __Example__
%> @code
%>   c = {'First', 'Second'}
%>   var = varOrCell(c,2)
%>   % 'Second'
%>   c = 'Third'
%>   var = varOrCell(c,2)
%>   % 'Third'
%> @endcode
%>
%> @author Rasmus Jones
%>
%> @version 1

%> @brief Returns variable or specified element of cell array
%>
%> Returns variable or specified element of cell array
%>
%> @param var         variable Variable in question
%> @param ii          Index Index in case of cell array
%>
%> @retval output1 Output value 1
%> @retval var Output value 1
function var=varOrCell(var,ii)
    if iscell(var)
        var = var{ii};
    end            
end

