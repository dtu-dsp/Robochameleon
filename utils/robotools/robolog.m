%>@file robolog.m
%>@brief Robochameleon log utility
%> 
%> @ingroup roboUtils
%>
%> * It can be used to log information to different log levels. See below.
%> * Logging in colors may slow down the code execution. For long and slow operations it's possible to log
%>   everything in black (faster) or totally disable the logging (even faster).
%>
%> __Log levels__
%> 
%> * ERR Errors. Will also break the code execution.
%> * WRN Warnings. Use it when the behaviour may create problems if gone unoticed.
%> * DBG Use it only in custom setups to display information for debugging. Don't use it in units or modules in the library.
%> * NFO Basic logging level used to display the status of normal operations that may be of interest to the user.
%> * NFO0 Should mostly used to display pedantic information which may be useful for debugging or to new users.
%>
%> __Logging preferences__
%>
%>   __WARNING__ Preferences are persistent. Reset them at the beginning of any script,
%>   and set the relevant ones manually to avoid mistakes. After changing the preferences run clear all to
%>   make them effective.
%>
%>   * setpref('roboLog', 'logToFile', VALUE) [Default: 0]
%>     - 0: Log to standard output
%>     - 1: Log to file
%>     - 2: Log both to standard output and file
%>     
%>   * setpref('roboLog', 'logFile', FILENAME)
%>   
%>   * setpref('roboLog', 'logLevel', LEVEL) [Default: Maximum]
%>     - 1: Log errors (ERR)
%>     - 2: Log errors and warnings (ERR, WRN)
%>     - 3: Log errors, warnings and custom debug info (ERR, WRN, DBG)
%>     - 4: Log errors, warnings, custom debug info, general info (ERR, WRN, DBG, NFO)
%>     - 5: Log errors, warnings, custom debug info, general info, and trivial info (ERR, WRN, DBG, NFO, NFO0)
%>
%>   * setpref('roboLog', 'logInBlack', LEVEL) [Default: 1]
%>     - 0: Don't use colors in log output (faster)
%>     - 1: Use colors in log output
%>
%> __Example__
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
%> 
%> @author Simone Gaiarin
%>
%> @version 1

%> @brief This function allows the user to print log messages in a standard way.
%>
%> @param msg The message to be logged. Can be a printf-like format string.
%> @param varargin{1} Log type. Possible values: {'ERR', 'WRN', 'NFO'}. Default: 'NFO'.
%> @param varargin{2:end} Printf arguments.
function robolog(msg, varargin)
%Constants
validLogTypeValues = {'ERR', 'WRN', 'DBG', 'NFO', 'NFO0'};
textColors = {[1 0 0], [1, 0.5, 0], [0 0.7 1],[0 0 0], [0 0 0]}; % Black, orange, red, cyan

% Get global preferences
persistent logToFile
persistent logFile
persistent logLevel
persistent logInBlack
if isempty(logToFile)
    logToFile=getpref('roboLog', 'logToFile', false);
    logFile=getpref('roboLog', 'logFile', 'robolog.txt');
    logLevel=getpref('roboLog','logLevel', length(validLogTypeValues));
    logInBlack=getpref('roboLog','logInBlack', 0);
end

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
    logTypeIdx = find(strcmp(validLogTypeValues,logType));
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

% if caller is unit, rather use the actual unit
if strcmpi(callerName,'unit')
   callerName = evalin('caller','class(obj)');
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
    msg=sprintf(['(Robo %s)\tIn %s: ', msg], logType, callerName, varargin{argIdx:end});
else
    msg=sprintf(['(Robo %s)\tIn %s: ', msg], logType, callerName);
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
    if strcmp(logType, 'NFO') || logInBlack
        fprintf(1, logMsg);
    else
        cprintf(textColors{logTypeIdx}, logMsg);
    end
end

end
