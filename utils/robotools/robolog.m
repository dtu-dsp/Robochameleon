%>@file robolog.m
%>@brief Robochameleon log utility
%> 
%> @ingroup roboUtils
%>
%> __Logging preferences__
%>
%>   __WARNING:__ Preferences are persistent. Reset them at the beginning of any script,
%>   and set the relevant ones manually to avoid mistakes.
%>
%>   * setpref('roboLog', 'logToFile', VALUE)
%>     - 0: Log to standard output
%>     - 1: Log to file
%>     - 2: Log both to standard output and file
%>     
%>   * setpref('roboLog', 'logFile', FILENAME)
%>   
%>   * setpref('roboLog', 'logLevel', LEVEL)
%>     - 1: Log errors
%>     - 2: Log errors and warnings 
%>     - 3: Log errors, warnings and info
%>
%> __Example:__
%> @code
%>   % Delete any previous log related settings
%>   if ispref('roboLog')
%>     rmpref('roboLog');
%>   end
%>   robolog('Info 1');
%>   robolog('Info 2', 'NFO');
%>   robolog('Warning 1', 'WRN');
%>   robolog('Formatted %s %d', 'WRN', 'warning', 2);
%>   
%>   % Enable logging to file only
%>   setpref('roboLog', 'logToFile', 1);
%>   robolog('Warning 3 to robolog.txt', 'WRN');
%>   
%>   % Set log file
%>   setpref('roboLog', 'logFile', 'myfile.txt');
%>   robolog('Info 3 to myfile.txt', 'NFO');
%>   
%>   robolog('ciao', 'ERR');
%> @endcode

%> @brief This function allows the user to print log messages in a standard way.
%>
%> It can be used to log info messages (NFO), warnings (WRN), and errors(ERR).
%> Logging an error will break the code execution.
%>
%> @param msg The message to be logged. Can be a printf-like format string.
%> @param varargin{1} Log type. Possible values: {'ERR', 'WRN', 'NFO'}. Default: 'NFO'.
%> @param varargin{2:end} Printf arguments.
%> 
%> @author Simone Gaiarin
%> @version 1
function robolog(msg, varargin)
%Constants
validLogTypeValues = {'ERR', 'WRN', 'NFO', 'DBG'};
textColors = {[1 0 0], [1, 0.5, 0], [0 0 0], [0 0.7 1]}; % Black, orange, red, cyan

% Get global preferences
logToFile=getpref('roboLog', 'logToFile', false);
logFile=getpref('roboLog', 'logFile', 'robolog.txt');
logLevel=getpref('roboLog','logLevel', 3);

if logLevel < 1
    error('Robochameleon log level must be >= 1');
end
%The second argument is the log type, check if it's valid.
%If not specified assume NFO level
isValid=0;
if nargin > 1 && ischar(varargin{1})
    [isValid, logTypeIdx] = ismember(varargin{1}, validLogTypeValues);
    if isValid
        logType = varargin{1};
        argIdx = 2;
    end
end

if nargin == 1 || ~isValid    
    logType = 'NFO';
    logTypeIdx = 3;
    argIdx = 1;
end

%Check the logLevel to know if we need to log this message
if logTypeIdx > logLevel
    return
end

%Get the name of the caller function
db = dbstack(1);
if ~isempty(db)
    callerName = strsplit(db(1).name, '.');
    callerName = callerName(1);
    callerName = callerName{:};
else
    % the caller is a script not a function
    callerName='main script';
end

%Double escape % and \ because we call sprintf twice
msg = strrep(msg, '%%', '%%%%');
msg = strrep(msg, '\\', '\\\\');
%Perform the logging
%If we have more than one arguments, all the arguments from the argidx are
%parameters for printf
if nargin > 1
    %What is passed as string argument to robolog (%s) should be treated as string
    %but since we are passing it into sprintf twice we need to escape % and \\.
    %There cannot be escape sequences into the string arguments.
    idx = cellfun(@isstr, varargin);
    varargin(idx) = strrep(varargin(idx), '%', '%%');
    varargin(idx) = strrep(varargin(idx), '\', '\\');
    msg=sprintf(['(Robo %s) In %s: ', msg], logType, callerName, varargin{argIdx:end});
else
    msg=sprintf(['(Robo %s) In %s: ', msg], logType, callerName);
end

%Detect newlines and align subsequent lines vertically to the first one by adding spaces
%Warning: We are passing the message two times through printf:
% \n > newline > remains newline (Should work, needs testing)
% What happens if we escape more? \\n \\\n \\\\n? Wierd things (Don't do it)
prefixLength = 16; % length('(Robo NFO) In : ')
spacedNewLine = ['\n' repmat(' ', 1, prefixLength + length(callerName))];
logMsg = strrep(msg, sprintf('\n'), spacedNewLine);
logMsg = [logMsg '\n'];

%If we need to log to file, we open it in append mode
if logToFile
    fileId = fopen(logFile, 'a');
    fprintf(fileId, logMsg);
    fclose(fileId);
end

%If the log type is an error, launch an error and break the code execution
if strcmp(logType, 'ERR')
    me = MException('robochameleon:genericError', logMsg);
    throwAsCaller(me);
else
    
% Log to console if logToFile is 0 or 2 (log both on file and terminal)
if logToFile == 2 || logToFile == 0
    if strcmp(logType, 'NFO')
        fprintf(1, logMsg);
    else
        cprintf(textColors{logTypeIdx}, logMsg);
    end
end

end