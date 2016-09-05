%>@file createRoboUnit.m
%>@brief Robochameleon utility to create a new unit with a basic template
%> 
%> @ingroup roboUtils
%>
%> __Example:__
%> @code
%>   % Initialize robochameleon path
%>   robochameleon
%>   % From the directory where the class file should be located
%>   createRoboUnit MyClass 1
%>   createRoboUnit('MyClass', 1) % Alternative calling
%> @endcode

%>@brief Creates a new unit with the given name and version
%> 
%> @param className The name of the class
%> @param version The version of the class
%> @param varargin{1} The robochameleon root path. (Not required if the init script 'robochameleon' has been executed.
function createRoboUnit(className, version, varargin)
    if nargin < 1 robolog('A class name must be specified.', 'ERR'); end
    if nargin < 2 robolog('A class version must be specified.', 'ERR'); end
    if nargin > 2        
        roboRoot = varargin{1};
    else
        roboRoot = getpref('robochameleon','roboRootFolder','NULL');
        if strcmp(roboRoot,'NULL')
            robolog('A folder must be specified or "robochameleon" must be run before', 'ERR');
        end 
    end
    if ~isnumeric(version)
        try
            % If the command is called as 'createRoboUnit MyClassName 1' the version is passed as string
            version = str2double(version);
        catch
        end
    end
    if ~isnumeric(version) || version<0 || version/round(version) ~= 1
        robolog('The version must be an integer positive number', 'ERR');
    end
    isOk = regexp(className, '^[a-zA-Z0-9]+$' ,'start');
    if isempty(isOk)
        robolog('The class name can only contain the following characters [a-z] [A-Z] [0-9]', 'ERR');
    end
    fullClassName = sprintf('%s_v%d', className, version);
    fullClassName(1) = upper(fullClassName(1));
    srcFile = sprintf('%s/library/demo/ClassTemplate_v1.m', roboRoot);
    dstFile = sprintf('./%s.m', fullClassName);
    
    s = fileread(srcFile);
    s = strrep(s, 'ClassTemplate_v1', fullClassName);
    s = strrep(s, '%', '%%'); %Escape percentage symbol
    s = strrep(s, '\', '\\'); %Escape escape symbol
    fid = fopen(dstFile, 'w');
    fprintf(fid, s);
    fclose(fid);
end
