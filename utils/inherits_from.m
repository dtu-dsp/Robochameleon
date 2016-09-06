%> @file inherits_from.m
%> @brief Determine whether an object inherits from a specified superclass
%>
%> Utility function for module construction - makes sure the next unit in a
%> module is in fact a unit.
%>
%> @version 1

%> @brief Determine whether an object inherits from a specified superclass
%>
%> @param obj           Object to test
%> @param className     Name of superclass
%>
%> @retval tf           Boolean true/false
function tf = inherits_from(obj,className)

tf = any(strcmp(className,superclasses(obj)));
