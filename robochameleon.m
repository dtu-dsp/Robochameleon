function robochameleon(varargin)
%> @file robochameleon.m
%> @brief Robochameleon initialization script
%>
%> @ingroup roboUtils
%> @param resetFlag {false | true}: restores matlab's path and reinitializes robochameleon
%> @author Robert Borkowski
%> rbor@fotonik.dtu.dk
%> Modified by
%> @author Miguel Iglesias Olmedo miguelio@kth.se
%> @version v1.1, 10.08.2015

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
    dirs = {'addons', 'base', 'files', 'library', 'utils', 'devel'};
    for i=1:numel(dirs)
        add = [root filesep dirs{i}];
        fprintf('-> %s\\*\n',add);
        addpath(genpath(add));
    end
    
    if verLessThan('matlab', '8.1.0')
        fprintf(1,'Adding compatibility layer for earlier MATLAB releases.');
        addpath(genpath([root 'compatibility']));
        rmpath(root, 'compatibility\bioinfo_lite');
    end
    
    v = ver('bioinfo');
    if isempty(v)
        addpath(genpath([root 'compatibility\bioinfo_lite']));
    end
    
    
    ROBO = true;
end
