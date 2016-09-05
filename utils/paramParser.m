%> @file paramParser.m
%> @brief This function translates structures of parameters into strings and strings into structrues.
%>
%> @ingroup roboUtils
%>
%> * Especially helpful when saving/loading traces.
%> * Parameters must be separated with '_' and you can for example use 'P10'
%> or 'P=10'. For string only '=' works i.e. 'filter=Gauss'.
%> * If the string is terminated with _n, it assigns n to parametere 'iteration'.
%>
%>
%> __Observations:__
%> * For string to structure, the string can contain an exension.
%> * For string to structure, the string can contain a prefix separated from the parameters by a double underscore.
%> * From structure to string, the string is returned without extension.
%>
%> __Example:__
%> @code
%>   'L20km_OSNR=20dBm_alpha0.3_2.mat'
%> @endcode
%>
%> translates to
%>
%> @code
%>   out.L=20
%>   out.OSNR=20
%>   out.alpha=0.3,
%>   out.iteration=2.
%> @endcode
%>
%> (And the other way around)
%>
%> __Parameters groups__
%>
%> The function also supports groups, i.e:
%>
%> @code
%> 'P10_fiber[Length=100_D=17]_EDFA[Gain10]_OSNR=10.mat'
%> @endcode
%>
%> translates to
%>
%> @code
%>   s.P = 10
%>   s.fiber.Length = 100
%>   s.fiber.D = 100
%>   s.EDFA.Gain = 10
%>   s.OSNR = 10
%> @endcode
%>
%> @author Miguel Iglesias Olmedo - miguelio@kth.se
%> @author Simone Gaiarin - simga@fotonik.dtu.dk
%>
%> @version 1


%> @brief Translates structures of parameters into strings and strings into structrues.
%>
%> @param in        A file name containing parameters or a structure of parameters.
%> @param prefix    A prefix that is appended at the beginning of the output string in struct>string mode. [Optional]
%>
%> @retval out      A structure of parameters or a file name without extension containing all the parameters.
function out = paramParser(in, varargin)

%% String -> Structure
if ischar(in)
    % Strip path and extension
    [~,name] = fileparts(in);
    
    %Strip text prefix
    name = strsplit(name, '__');
    if numel(name) <= 2
        name = name{numel(name)};
    else
        robolog('Multiple text prefixes detected. Name is bad formatted', 'ERR');
    end
    
    % Gets the iteration that is the number after the last separators (if present) (..._1)
    regex= 'w*[_\s]\d+'; % Possible separators: _ \s(space)
    iteration = regexp(name,regex,'match');
    if ~isempty(iteration)
        iteration = iteration{end};
        it = str2double(iteration(2:end));
        name = regexprep(name,regex,''); % Strip iteration from string
    else
        it = 0;
    end
    param.iteration=it;
    
    % The string can be formatted as follow to support substructures:
    % 'P10_fiber[Length=100_D=17]_EDFA[Gain=10]_Length=10_10'
    
    % We first select the subgroups delimited by []
    paramGroups = regexp(name,'[^_\s]+\[[^\]]+\]','match');
    % and we add a last group with the ungrouped parameters
    paramGroups{end+1} = regexprep(name,'_[^_\s]+\[[^\]]+\]','');
    
    for grp=paramGroups
        [m, tks] = regexp(grp,'([^_\s]+)\[([^\]]+)\]','match', 'tokens');
        subField = '';
        if ~isempty(m{1})
            % If the current group is a real group (and not the ungrouped group)
            tokens = tks{1}{1};
            keyValuePairs = tokens{2};
            subField = tokens{1};
            % Gets the parameters. Possible separators of the pairs are: _ space
            strpairs = strsplit(keyValuePairs,{'_',' '});
        else
            strpairs = strsplit(grp{1},{'_',' '});
        end
        
        % Gets the parameter name and value. Possible separators of the
        % key/value are: = : nothing(for numerical value only)
        regex = '-?(\d*\.)?\d+(e-?\d+)*'; % Regexp to match a number can be integer/float,
                                          % positive/negative and in  scientific notation
        for i=1:length(strpairs)
            try
                % First try to assume we have a numerical parameter
                num = regexp(strpairs{i},regex, 'match');
                num = num{1};
                rest = strsplit(strpairs{i},num);
                key = rest{1}; % Strip suffix to the number (like dBm)
                % Gets rid of separators ('=' and ':')
                key = regexprep(key, '[:=]', '');
                if ~isempty(subField)
                    param.(subField).(key) = str2double(num);
                else
                    param.(key) = str2double(num);
                end
            catch
                % If the previous fails, let's assume we have a string parameter
                try
                    KeyValue = strsplit(strpairs{i}, {'=', ':'});
                    fieldName = KeyValue{1};
                    value = KeyValue{2};
                    if ~isempty(subField)
                        param.(subField).(fieldName) = value;
                    else
                        param.(fieldName) = value;
                    end
                catch
                    error('Params were not well separated in the sring in file: %s.', in);
                end
            end
        end
    end
    out = param;
    
    
%% Structure -> String
elseif isstruct(in)
    if ~isempty(varargin)
        prefix = varargin{1};
        if ~ischar(prefix)
            robolog('The prefix should be a string.', 'ERR');
        end
    end

    param = in;
    str = '';
    fields = fieldnames(param);
    iteration=0;
    for i=1:length(fields)
        if strcmp(fields{i},'iteration')
            iteration=param.iteration;
        elseif strcmp(fields{i},'iter')
            iteration=param.iter;
        elseif strcmp(fields{i},'it')
            iteration=param.it;
        else
            str = [str fields{i} '=' value2str(param.(fields{i})) '_'];
        end
    end
    if iteration
        str = [str num2str(iteration)];
    else
        str = str(1:end-1);
    end
    if ~isempty(prefix)
        out = [prefix '__' str];
    else
        out = str;
    end
else
    error('Give me a structure or a string')
end
end

function strValue = value2str(value)
    strValue = num2str(value);
    % If it's a decimal, remove leading zeros and use scientific notation
    if strfind(strValue, '.')
        vals = strsplit(strValue, '.');
        if vals{1} == '0'
            deci = vals{2};
            i = 1;
            while deci(i) == '0'
                i = i + 1;
            end
            deci = deci(i:end);
            if length(deci) > 1
                strValue = sprintf('%s.%se-%d', deci(1), deci(2:end), i);
            else
                strValue = sprintf('%se-%d', deci(1), i);
            end
        end
        return
    end
    % Remove trailing zeros
    i = 0;
    while strValue(end-i) == '0'
        i = i + 1;
    end
    if i > 0
        nonZeroPart = strValue(1:end-i);
        if length(nonZeroPart) > 1
            strValue = sprintf('%s.%se%d', nonZeroPart(1), nonZeroPart(2:end), i);
        else
            strValue = sprintf('%se%d', nonZeroPart, i);
        end
    end
end
