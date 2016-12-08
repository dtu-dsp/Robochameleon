%> @file robohelp.m
%> @brief Open the robochameleon help main page or a class/function documentation in the browser.
%>
%> @ingroup roboUtils
%>
%> __Notes__
%>
%> The system browser must be specified in Preferences > MATLAB > web.
%>
%> __Example__
%>
%> @code
%>   % Open the help main page
%>   robohelp
%>
%>   % Open class help page
%>   robohelp NonlinearChannel_v3
%>
%>   % Open class help page (partial match)
%>   robohelp BERT
%> @endcode
%>
%> @author Simone Gaiarin
%>
%> @version 1

%> @brief Open the robochameleon help main page or a class/function documentation in the browser.
%>
%> Open the main page of the robochmeleon help if no arguments are specified.
%> If a search string is specified, it tries to find a class/file containing that string.
%> An extra parameter containing 'c' can be specified to limit the search to classes only.
%>
%> @param varargin{1} Query string.
%> @param varargin{2} Type. Possible values = {'c' = Class}.
function robohelp(varargin)
    roboRoot = getpref('robochameleon','roboRootFolder','NULL');
    if strcmp(roboRoot,'NULL')
        robolog('Run "robochameleon" to initialize the robochameloen path.', 'ERR');
    end
    
    excludePaths = '\.git|user manual'; %Regexp format
    if ~isempty(varargin)
        searchTerm = varargin{1};
        searchTerm = strrep(searchTerm, '*', '.*'); % * match all, shell style
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
                    if isempty(fullName) || strcmp(namee, searchTerm)
                        % Do this on the first match and also if the file name matches COMPLETELY the
                        % searchTerm
                        fullName = namee;
                    elseif isempty(regexp(searchTerm, '[tTest]', 'once')) && ...
                            ~isempty(regexp(namee, '[tT]est', 'once'))
                        % This will avoid the unit testers to match as duplicate, but if we are looking for a
                        % unit tester it will fail if there are multiple matches of the search term.
                        continue;
                    else
                        robolog('Search query matches multiple classes/files. Ignoring %s.', 'WRN', namee);
                    end
                end
            end
        end
        robolog('Opening documentation for class %s', fullName);
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
