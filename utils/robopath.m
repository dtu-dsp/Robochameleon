%> @file robopath.m
%> @brief Outputs the full path of whatever is passed
%>
%> Example:
%>
%> @code
%> robopath('traces/experiment/test.mat')
%>   C:\Users\Miguel\Documents\MATLAB\RobochameleonKTH\
%> @endcode
%>
%> @author Miguel Iglesias Olmedo
%>
%> @version 1

%> @brief Outputs the full path of whatever is passed
%>
%> @param path      Sub-folder of interest
%> 
%> @retval          Full path to subfolder
function fullpath = robopath( path )

robopath = getpref('robochameleon');
if path(1) == '/' || path(1)=='\'
    fullpath = [robopath.roboRootFolder path];
else
    fullpath = [robopath.roboRootFolder '/' path];
end
end

