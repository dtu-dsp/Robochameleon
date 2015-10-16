%> @file robohelp.m
%> @brief Open the robochameleon help
%>
%> __Notes:__
%>
%> The system browser must be specified in Preferences > MATLAB > web.
%>
%> @brief Open the main page of the doxygen robochameleon help in the system browser
%> 
%> Open the index page of the robochmeleon help if no argument specified.
%> If a search string is specified, it tries to find a class/file containing that string.
%> An extra parameter containing 'c' can be specified to limit the search to classes only.
%>
%> @param varargin{1} Query string
%> @param varargin{2} Type. Possible values = {'c' = Class}
function robohelp(varargin)
    roboRoot = getpref('robochameleon','roboRootFolder','NULL');
    if strcmp(roboRoot,'NULL')
        robolog('Run "robochameleon" to initialize the robochameloen path.', 'ERR');
    end
    
    excludePaths = '\.git|user manual'; %Regexp format
    if ~isempty(varargin)
        searchTerm = varargin{1};
        classOnly = 0;
        if length(varargin) > 1
            if strcmp(varargin{2}, 'c')
                %Search only for classes
                classOnly = 1;
            end
        end
        fileList = getAllFiles(roboRoot);
        fullName = '';
        for i=1:length(fileList)
            [fpath, namee] = fileparts(fileList{i});
            if isempty(regexp(fpath, excludePaths, 'once'))
                if ~isempty(regexp(namee, searchTerm, 'once'))
                    if classOnly && ~(exist(namee, 'class') == 8)
                        continue;
                    end                    
                    if isempty(fullName)
                        fullName = namee;
                    else
                        robolog('Search query matches multiple classes/files', 'ERR');
                    end                    
                end
            end
        end
        if isempty(fullName)
            robolog('Search query didn''t match anything.', 'ERR');
        end
        fullNameParsed = regexprep(fullName, '([A-Z_])', '_$1');
        fullNameParsed = lower(fullNameParsed);
        if exist(fullName, 'class') == 8
            url = sprintf('%s/doc/user manual/html/class%s.html', roboRoot, fullNameParsed);
        else
            url = sprintf('%s/doc/user manual/html/%s_8m.html', roboRoot, fullNameParsed);
        end
    else
        url = sprintf('%s/doc/user manual/html/index.html', roboRoot);
    end
        
    web(url, '-browser');
end
