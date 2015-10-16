function fullpath = robopath( path )
%ROBOPATH outputs the full path of whatever is passed
%   Ex: robopath('traces/experiment/test.mat')
%   C:\Users\Miguel\Documents\MATLAB\RobochameleonKTH\
robopath = getpref('robochameleon');
if path(1) == '/' || path(1)=='\'
    fullpath = [robopath.roboRootFolder path];
else
    fullpath = [robopath.roboRootFolder '/' path];
end
end

