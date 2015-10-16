%>@file compileMex_v1.m
%>@brief Compiles all the c/cpp mex files in the robochameleon project
%> 
%> @ingroup roboUtils
%>
%> If you have initialized your project with the _robochameleon_ script, the root folder
%> will be retrived automatically
%>
%> @param Robochameleon root folder (optional) Default: try to retrieve it automatically
%>
%> @author Simone Gaiarin
%> @version 1
function compileMex(varargin)
    if nargin > 0
        roboRoot = varargin{1};
    else
        roboRoot = getpref('robochameleon','roboRootFolder','NULL');
        if strcmp(roboRoot,'NULL')
            error('A folder must be specified or "robochameleon" must be run before');
        end 
    end            
    fileList = getAllFiles(roboRoot);
    for i=1:length(fileList)
        [~,~,ext] = fileparts(fileList{i});
        if strcmp(ext, '.c') || strcmp(ext, '.cpp')
            %Strip the root path from the current file for log purposes
            tokens = regexp(fileList{i}, [roboRoot '(.*)'], 'tokens');
            cfile = tokens{1};
            robolog('Compiling %s', cfile{:});
            %Perform the compilation. May fail if a compiler is missing, or external libraries are missing
            try
                mex(fileList{i});
            catch ME
                robolog('Failed compiling %s\nError is:\n%s', 'WRN', cfile{:}, ME.message);                
            end
        end
    end
end
