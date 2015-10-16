function out = paramParser(in)
% This function translates structures into strings and strings into
% structrues. Especially helpful when saving/loading traces. For example:
% L20km_OSNR=20dBm-alpha:0.3_2.mat -> out.L=20, out.OSNR=20, out.alpha=0.3,
% out.iteration=2. And the other way around.
% @author Miguel Iglesias Olmedo - miguelio@kth.se

%% String -> Structure
if ischar(in)
    name = in;
    % Gets the iteration (..._1)
    regex= 'w*(_|-|\s)\d+';
    iteration = regexp(name,regex,'match');
    if ~isempty(iteration)
        iteration = iteration{end};
        it = str2double(iteration(2:end));
    else
        it = 0;
    end
    param.iteration=it;
    
    % Gets rid of '=' and ':'
    name = strrep(name,'=','');
    name = strrep(name,':','');
    
    % Gets the parameters
    strpairs = strsplit(name,{'_','-',' '});
    if ~isempty(iteration)
        strpairs=strpairs(1:end-1);
    end
    
    % Gets the parameter name and value
    regex = '(\d*\.)?\d+';
    for i=1:length(strpairs)
        num = regexp(strpairs{i},regex, 'match');
        if length(num) == 1
            num = num{1};
        else
            error('Params were not well separated in the sring')
        end
        rest = strsplit(strpairs{i},num);
        param.(rest{1}) = str2double(num);
        out = param;
    end
    
%% Structure -> String
elseif isstruct(in)
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
            str = [str fields{i} '=' num2str(param.(fields{i})) '_'];
        end
    end
    if iteration
        str = [str num2str(iteration)];
    else
        str = str(1:end-1);
    end
    out = str;
else
    error('Give me a structure or a string')
end