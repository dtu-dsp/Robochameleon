%> @file paramDeepCopy.m
%> @brief Copy parameters aligned to the properties of a module/unit
%>
%> @ingroup {utils}
%>
%> Copy all parameters of a parameters struct, which have the same names as
%> the module properties and all its unit properties.
%>
%> __Example__
%> @code
%>   param.M                 = 4;
%>   param.modulationFormat  = 'QAM';
%>   param.samplesPerSymbol  = 16;
%>   param.pulseShape        = 'rrc';
%>   param.rollOff           = 0.2;
%>   sg_param=paramDeepCopy('SymbolGenerator_v1',param)
%>   ps_param=paramDeepCopy('PulseShaper_v2',param)
%> @endcode
%>
%>
%> @author Rasmus Jones
%>
%> @version 1

%> @brief Copy parameters aligned to the properties of a module/unit
%>
%> Copy all parameters of a parameters struct, which have the same names as
%> the module properties and all its unit properties.
%>
%> @param class             Name of module/unit, e.g. WavformGenerator_v1
%> @param param             Struct of parameters
%>
%> @retval param_copied     Struct of copied parameters aligned to given module/unit
function [ param_copied ] = paramDeepCopy( class, param )
    if(~ischar(class))
        robolog('Variable class is supposed to be a string/char.','ERR');
    end
    if(~isstruct(param))
        robolog('Variable param is supposed to be a struct.','ERR');
    end    
    param_copied = struct;
    % Get all field names of the param struct
    names=fields(param);
    % Check whether the class is a module or unit
    if(isModule(class))
        tree=getInternalUnitsNested(class);
        props=unique(getUnitsTreeProperties(tree));
    else        
        props=properties(class);
    end
    props{find(cellfun(@(x) strcmpi(x,'nOutputs'),props))}='NOPROPERTY';
    props{find(cellfun(@(x) strcmpi(x,'nInputs'),props))}='NOPROPERTY';
    names=unique(names);
    props=unique(props);
    members_names=cellfun(@sum,cellfun(@(name) cellfun(@(prop) myRegex(prop,name), props), names, 'UniformOutput',false))~=0;
    if sum(members_names)
        temp=[{names{members_names}}; {names{members_names}}];
        eval(sprintf('param_copied.%s=param.%s;',temp{:}));
    else
%         robolog('No parameters match the properties of this unit/module (%s).','WRN',class);
    end
end

function result = myRegex(prop,name)
    if length(prop)~=1
        result = ~isempty( regexpi(name,[prop '\>'],'match') );
    else
        result = ~isempty( regexp(name,[prop '\>'],'match') );
    end
end

%> @brief Gather all units within a module as tree structure of cell arrays
%>
%> Creates a tree structure of cell arrays where the leafs hold all unit
%> names of the module in question
%>
%> @param moduleName        Module in question
%>
%> @retval names            Tree structure of cell arrays with unit names as leafs
function names = getInternalUnitsNested( moduleName )
    names = getInternalUnits( moduleName );
    names{length(names)+1}={moduleName};
    for ii=1:length(names)-1
       if(isModule(names{ii}{1}))           
           names{ii}=getInternalUnitsNested( names{ii}{1} );
       end
    end    
end

%> @brief Gather all units/modules within a modules constructor
%>
%> Helper function that extracts the unit/module names from the constructor
%> of a module
%>
%> @param moduleName        Module in question
%>
%> @retval names            List of units/modules extracted from module in questions
function names = getInternalUnits( moduleName )
    if(~isModule(moduleName))
        robolog('%s is not a module.','ERR',moduleName);
    end
    text = fileread([moduleName '.m']);
    %% remove comments
    [startIndex,endIndex]=regexp(text,'\%.*?\n');
    text_wo='';
    for n=1:length(endIndex)-1
        if(endIndex(n)~=startIndex(n+1)-1)
           add = text(endIndex(n):startIndex(n+1)-1);
           text_wo = [text_wo add]; 
        end    
    end
    text = [text_wo text(endIndex(n+1):end)];
    %% extract constructor
    [~,endIndex] = regexp(text,['function[a-zA-Z0-9\[\]\,\;\=\s]*' moduleName '.*?)']);
    text=text(endIndex:end);
    words={'for', 'while', 'switch', 'try', 'if', 'parfor'};
    % very ugly implementation since counter is not functional
    % it depends on text which isnt a passed variable (but it works)
    counter = @(word) length(regexp(text,['\<' word '\>']));
    count=sum(cellfun(counter,words));
    endPos = regexp(text,'\<end\>');
    constructor_text=text(1:endPos(count+1));
    %% look for units/modules
    [~,names]=regexp(constructor_text,'=\s([a-zA-Z]+_v\d)\(','match', 'tokens');
end

%> @brief Gather all properties from a tree structure of units
%>
%> Helper function that extracts all the properties of a tree structure
%> created by getInternalUnitsNested()
%>
%> @param tree              Tree structure from getInternalUnitsNested()
%>
%> @retval props            List of properties from all units within the tree structure
function props = getUnitsTreeProperties(tree)
    props={};
    for ii=1:length(tree)
        if(length(tree{ii})>1)
            props=[props; getUnitsTreeProperties(tree{ii})];
        elseif(length(tree{ii})==1)
            props=[props; properties(cat(1,tree{ii}{1}))];
        end
    end
end
