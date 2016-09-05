%> @file isModule.m
%> @brief 
%> 
%> @ingroup roboUtils
%>
%> @brief Checks whether the class name is a module
%> 
%> Helper function that checks whether the class name is a module
%>
%> @param class classname as string
%> 
%>
%> @author Rasmus Jones
function y = isModule( klass )
    if(~ischar(klass))
        robolog('class is supposed to be a string/char.','ERR');
    end
    temp=superclasses(klass);
    if(isempty(temp))
        y=0;
    else
        if iscell(temp)
            y=any(cellfun(@(x)strcmp(x,'module'),temp));
        else
            y=strcmp(temp,'module');
        end
        
    end    
end