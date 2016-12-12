%> @file robochameleon.m
%> @brief Robochameleon initialization script
%>
%> @ingroup roboUtils
%>
%> Add the robochameleon directories to the MATLAB path. It's possible to
%> specify extra directories to be added to the path by setting the global
%> preference _extrapathdir_ (cellarray of strings) in the group _robochameleon_.
%> The setting is persistent.
%>
%> __Example__
%>
%> To add the directories execute:
%> @code
%> setpref('robochameleon', 'extrapathdirs', {'lab', ['bindings' filesep 'vpi']})
%> @endcode
%> To remove it execute:
%> @code
%> rmpref('robochameleon', 'extrapathdirs')
%> @endcode
%>
%> @author Robert Borkowski <rbor@fotonik.dtu.dk>
%> @author Miguel Iglesias Olmedo <miguelio@kth.se>
%> @author Simone Gaiarin <simga@fotonik.dtu.dk>
%> @version v1.2, 11.11.2015

%> @brief Add robochameleon related directories to the MATLAB path.
%> 
%> @param resetFlag Restores matlab's path and reinitializes robochameleon. Possible values: {false | true}. [Optional]
function robochameleon(varargin)

mlock; % Protect function against clear
persistent ROBO; if isempty(ROBO), ROBO = false; end % Initialize ROBO on creation
resetFlag = false;
if nargin > 0
    resetFlag=varargin{1};
end
if resetFlag
    restoredefaultpath
end

if ~ROBO || resetFlag % Check if previous initialization was successful
    root = mfilename('fullpath');
    root = root(1:find(root==filesep,1,'last')-1); % Get directory of this file
    setpref('robochameleon','roboRootFolder',root);
    
    fprintf(1,'Initializing Robochamelon. Adding directories to path:\n');
    fprintf('-> %s\n',root);
    addpath(root);

    dirs = {'addons', 'base', 'files', 'library', 'utils', 'devel', 'lab', 'view'};
    % Add user defined directories to path
    if ispref('robochameleon', 'extrapathdirs')
        extradirs=getpref('robochameleon', 'extrapathdirs');
        dirs = [dirs extradirs];
    end


    for i=1:numel(dirs)
        add = [root filesep dirs{i}];
        fprintf('-> %s\\*\n',add);
        addpath(genpath(add));
    end
    
    if verLessThan('matlab', '8.1.0')
        fprintf(1, 'Adding compatibility layer for MATLAB releases before 8.1.0 (R2013a).\n');
        addpath(genpath(fullfile(root, 'compatibility', '8.1')));
    end
    
    if verLessThan('matlab', '8.5.0')
        fprintf(1, 'Adding compatibility layer for MATLAB releases before 8.5.0 (R2015a).\n');
        addpath(genpath(fullfile(root, 'compatibility', '8.5')));
    end
    v = ver('bioinfo');
    if isempty(v)
        fprintf(1, 'Adding compatibility layer bioinfo_lite.\n');
        addpath(genpath(fullfile(root, 'compatibility', 'bioinfo_lite')));
    end
    v = ver('stats');
    if isempty(v)
        fprintf(1, 'Adding compatibility layer stats_lite.\n');
        addpath(genpath(fullfile(root, 'compatibility', 'stats_lite')));
    end
    
    fprintf(1, '\nTo access the robochameleon documentation run: robohelp\n\n');
    
    % Disable warnings
    warning('off','catstruct:DuplicatesFound');
    
    ROBO = true;
end
