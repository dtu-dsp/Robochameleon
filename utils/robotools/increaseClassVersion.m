%>@file increaseClassVersion.m
%>@brief Robochameleon utility to increase class version safetly
%> 
%> @ingroup roboUtils
%>
%> This utility creates a new file with an increased version number and changes all the internal references to
%> the previous version number in an automated way. If the target file is in the MATLAB PATH the script can
%> be from any folder, and the new file will be placed in the same folder as the original file.
%> 
%> On unix systems it also checks that the source file is git-clean (no modifications present). In both Linux
%> and Windows it provides instructions on how to properly increase the version number without loosing
%> modifications tracking in git.
%>
%> The proper way to proceed is:
%>   1. Stash your files.
%>   2. Call increaseClassVersion
%>   3. Add the newly created class file to git and commit.
%>   4. Call increaseClassVersion with the 'force' option to apply uncommitted modifications on the new file.
%>                    
%> __Example:__
%> @code
%>   % From the directory where the class file is located
%>   % Case 1: File is git clean
%>   increaseClassVersion MyClass_v2
%> 
%>   % Case 2: Uncommitted modifications on the file
%>   % Git stash
%>   increaseClassVersion MyClass_v2
%>   % Git add and commit the new file
%>   % Git apply (unstash)
%>   increaseClassVersion MyClass_v2 'force'
%> @endcode

%>@brief Increase the class version safetly and creates a new class file
%> 
%> @param classInputText The class name or the class file name
%> @param varargin{1} Force flag. If 'true' force overwriting the destination file and ignore git checks. Possible value: {'force'}. [Default: disabled]
function increaseClassVersion(classInputText, varargin)
    forceEnabled = 0;
    if length(varargin) > 0
        if strcmp(varargin{1}, 'force');
            forceEnabled = 1;
        end
    end
    % Identify if the user specified the name with the extension
    matched = regexp(classInputText, '^.*\.m', 'start');
    
    %Try to strip the path from file name if any
    [~, classInputTextStripped] = fileparts(classInputText);
    
    % Retrieve the root class name and the version as regexp tokens    
    if matched
        tkns = regexp(classInputTextStripped, '^([a-zA-z0-9_-]+)_v([0-9]+)\.m', 'tokens');    
    else
        tkns = regexp(classInputTextStripped, '^([a-zA-z0-9_-]+)_v([0-9]+)', 'tokens');    
    end
    
    % Raise an error if we fail to parse the input text
    if sum(size(tkns)) < 2
        robolog('It was not possible to parse either the class name or the version number from the given name', 'ERR');
    end
    
    % Retrieve the root class name and the version from the tokens
    tokens = tkns{1};
    classRootName = cell2mat(tokens(1));    
    try
        currentVersion = str2num(cell2mat(tokens(2)));
    catch e
        robolog('The file name format must be ClassName_vX.m, where X is an integer number.', 'ERR');
    end
    
    className = sprintf('%s_v%d', classRootName, currentVersion);
    classFileName = sprintf('%s_v%d.m', classRootName, currentVersion);
    newVersion = currentVersion + 1;
    newClassName = sprintf('%s_v%d', classRootName, newVersion);
    newClassFileName = sprintf('%s_v%d.m', classRootName, newVersion);
    
    % Check if input class file exists
    if exist(classFileName, 'file') ~= 2 
        robolog('The specified class file doesn''t exist.', 'ERR');
    end
    
    % Check that the class file is git-clean, so we avoid loosing modifications tracking.
    % The check can be performed in Linux but I think it's not possible in Windows because the git
    % executable is not in the PATH, so let's just print a warning
    if isunix        
        [a, isModified] = system(['git ls-files -m ' classFileName]);
        if findstr('fatal: Not a git repository', isModified)
            robolog('You need to be in a folder within the git repository before running this command.', 'ERR');
        end
        if ~isempty(isModified) && ~forceEnabled
            robolog(['The class file is not git-clean.\n' ...
                    'You should:\n' ...
                    '  1. Stash your files.\n' ...
                    '  2. Call increaseClassVersion.\n' ...
                    '  3. Add the newly created class file to git and commit.\n' ...
                    '  4. Call increaseClassVersion with the ''force'' option.\n' ...
                    'In this way the newly created file will show the modifications from the ' ...
                    'previous version of the class and everything will be nicely tracked in git.' ...
                ], 'ERR');
        end
    elseif ispc
        robolog(['The class file should be git-clean before calling this function.\n' ...
                    'You should:\n' ...
                    '  1. Stash your files.\n' ...
                    '  2. Call increaseClassVersion.\n' ...
                    '  3. Add the newly created class file to git and commit.\n' ...
                    '  4. Call increaseClassVersion with the ''force'' option.\n' ...
                    'In this way the newly created file will show the modifications from the \n' ...
                    'previous version of the class and everything will be nicely tracked in git.' ...
                ], 'WRN');
    else
        robolog('Can''t determine system platform.','ERR');
    end
    %  Check if output class file exists to avoid overwriting it
    if exist(newClassFileName, 'file') == 2 && ~forceEnabled
        robolog('The target class file name already exists!', 'ERR');
    end
    
    % Increase the version of the class and change all the internal reference to the
    % class name (class name, constructor, ecc.)
    s = fileread(classFileName);
    s = strrep(s, className, newClassName);
    s = strrep(s, '%', '%%'); %Escape percentage symbols
    s = strrep(s, '\', '\\'); %Escape backslash symbols
    absPath = fileparts(which(classFileName));
    newClassFullName = [absPath filesep newClassFileName];
    fid = fopen(newClassFullName, 'w');
    fprintf(fid, s);   
    fclose(fid);
    robolog('New file created: %s', newClassFullName);
end
