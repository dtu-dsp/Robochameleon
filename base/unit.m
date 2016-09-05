%> @file unit.m
%> @brief Superclass: basic building block to hold functions
%>
%> @class unit
%> @brief Superclass: basic building block to hold functions
%> 
%> @ingroup base
%>
%> Everything that operates on a signal_interface object should be defined 
%> as a  class that inherits certain properties from unit.  For example:
%> @code
%> classdef MyClass_v1 < unit
%> ...
%> end
%> @endcode
%> 
%> All units must have the following properties:
%> - nInputs number of inputs
%> - nOutputs number of output
%> And the following method
%> - traverse
%> traverse acts like main in c programs.  It defines what function the
%> unit performs on the signal.
%>
%> @author Robert Borkowski
%> @version 1
classdef unit < handle    
    properties (GetAccess=public,SetAccess=protected,Hidden=true)
        %> Buffer for storing inputs as we traverse the graph
        inputBuffer = {}; 
        %> Children nodes
        nextNodes = {}; 
        %> Destination inputs in children
        destInputs = []; 
    end
    
    properties (GetAccess=public,SetAccess=public)
        %> For storing results
        results; 
        label;
        %> enable/disable plotting
        draw = [];
    end
    
    properties (GetAccess=public,SetAccess=private,Hidden)
        ID;
    end
    
    properties (Abstract=true,Hidden=true)
        %> Number of signals traverse expects
        nInputs; 
        %> Number of outputs traverse expects
        nOutputs; 
    end
    
    methods (Abstract)
        %> Main function call
        varargout = traverse(obj,varargin);
    end
    
    methods
        
        function obj = unit
            %> Set unique ID when creating a unit
            obj.ID = java.rmi.server.UID();
            obj.label = class(obj);
            
            % Draw by default
            if isempty(obj.draw), obj.draw = true; end
        end
        
        %> @brief Apply function contained in unit to signal
        %>
        %> Displays name of node and executes function contained in each
        %> unit on input signal(s).
        %>
        function traverseNode(obj)
            robolog('Traversing ...');
            %Check # of inputs and outputs
            if obj.nInputs~=numel(obj.inputBuffer);
                robolog('Number of connected inputs must be equal to the number of module inputs. %s has %d inputs; %d in were given', 'ERR', obj.label, obj.nInputs, numel(obj.inputBuffer));
            end
            if obj.nOutputs~=numel(obj.nextNodes);
                robolog('Number of outputs must be equal to the number of connected units. %s has %d outputs; %d destination units were specified', 'ERR', obj.label, obj.nOutputs, numel(obj.nextNodes));
            end
            
            % Helper function with one argument. Checks if all elements of
            % a cell array are of class signal_interface
            areallsignalinterfaces = @(var)all(cellfun(@(obj)isa(obj,'signal_interface'),var));
            
            % Check if inputs are ready
            if ~areallsignalinterfaces(obj.inputBuffer)
                robolog('The inputs are not ready yet. Incorrect topology ordering.', 'ERR');
            end
            [outputs{1:obj.nOutputs}] = traverse(obj,obj.inputBuffer{:}); % Traverse the unit
            if(~ispref('robochameleon','debugMode') || ~getpref('robochameleon','debugMode'))
                obj.inputBuffer = {}; % Remove processed inputs to save memory
            end
            
            % Draw figures
            if obj.draw, drawnow; end
            
            % Check if outputs are correctly returned: as a cell array, all
            % of class signal_interface and their number agrees with
            % nOutputs
            if ~iscell(outputs) || ~areallsignalinterfaces(outputs)
                robolog('Output from the traverse function is not a cell array or not all of its elements are of class signal_interface.', 'ERR');
            end
            if numel(outputs)~=obj.nOutputs
                %Changed from error to warning on June 12 2014 by Molly
                %robolog('Size of the outputs cell is incorrect (expected vector with length %d, got %d).',obj.nOutputs,numel(outputs));
                robolog('Size of the outputs cell has changed (expected vector with length %d, got %d).', 'WRN', obj.nOutputs,numel(outputs));
            end
            
            % Find all connected outputs
            conn = find(cellfun(@(obj)inherits_from(obj,'unit'),obj.nextNodes));
            % Write all outputs to the inputBuffer of the connected units
            for i=conn
                writeInputBuffer(obj.nextNodes{i},outputs{i},obj.destInputs(i));
            end
        
        end
        
        %> @brief Specify where signal should go next
        %>
        %> Connects one output of one unit to the inputs of the next
        %> For use in modules
        %>
        %> Complicated example:
        %> @code
        %> %% Construct some units (a 90 degree hybrid and two balanced pairs)
        %> hyb1 = OpticalHybrid_v1(param.hyb);
        %> bpd1 = BalancedPair_v1(param.bpd);
        %> bpd2 = BalancedPair_v1(param.bpd);
        %> %% attach the hybrid outputs to the BPDs
        %> hyb1.connectOutput(bpd1, 1, 1);
        %> hyb1.connectOutput(bpd1, 2, 2);
        %> hyb1.connectOutput(bpd2, 3, 1);
        %> hyb1.connectOutput(bpd2, 4, 2);
        %> @endcode
        %> This will have the following connection diagram
        %> \image html "BlockDiagUnitExplanation.jpg" width=100px
        %>
        %> @param uobj which unit to connect to
        %> @param unitOutput which unit output to connect
        %> @param nextUnitInput which input to connect to
        %>
        %> @see module
        function connectOutput(obj,uobj,unitOutput,nextUnitInput)
            % Connects a single output to a single input
            if ~inherits_from(uobj,'unit')
                robolog('All successive nodes must inherit from unit.', 'ERR');
            end
            obj.nextNodes{unitOutput} = uobj;
            obj.destInputs(unitOutput) = nextUnitInput;
        end
        
        %> @brief Specify where signal should go next
        %>
        %> Connects all the outputs of one unit to the inputs of the next.
        %> For use in modules
        %>
        %> Connects all the outputs of one unit to the inputs of the next
        %> set of units.
        %> 
        %> Complicated example:
        %> @code
        %> %% Construct some units (a 90 degree hybrid and two balanced pairs)
        %> hyb1 = OpticalHybrid_v1(param.hyb);
        %> bpd1 = BalancedPair_v1(param.bpd);
        %> bpd2 = BalancedPair_v1(param.bpd);
        %> %% attach the hybrid outputs to the BPDs
        %> hyb1.connectOutputs({bpd1 bpd1 bpd2 bpd2}, [1 2 1 2]);
        %> @endcode
        %> This will have the following connection diagram
        %> \image html "BlockDiagUnitExplanation.jpg" width=100px
        %> Note the implied order of unit outputs is 1,2,3,...
        %>
        %>  __Notes on syntax:__
        %> 1. The set of destinations should be passed as a cell array.
        %>  If they are passed as a regular array, this function will
        %> attempt to convert to cell array, but this is not ideal.
        %> 2. The destination inputs can be omitted if: 
        %> 
        %>      (a) There is one destination unit and all source outputs 
        %>      connect sequentially to all destination outputs OR 
        %> 
        %>      (b) There is exactly one destination unit for each source
        %>      output.
        %>
        %> @param units object, or cell array of objects, to connect to
        %> @param destInputs which input to connect to
        %>
        %> @see module
        function connectOutputs(obj,units,destInputs)
            
            %convert input array of units to cell array
            %necessary to keep this to deal with 1x1 case - overwriting
            %horzcat and vertcat doesn't cover this case
            if ~iscell(units)
                units = mat2cell(units(:), ones(1, numel(units)), 1);
            end
            
            % If destination port not specified, assign based on context.
            % Throw an error if this is not possible.
            if nargin<3 
                if numel(units)==obj.nOutputs
                    destInputs = ones(1,obj.nOutputs);
                elseif (numel(units)==1) && (units{1}.nInputs == obj.nOutputs)
                    destInputs = 1:obj.nOutputs;
                    units = repmat(units, obj.nOutputs, 1);
                else
                    robolog('Destination inputs must be specified.', 'ERR');
                end
            elseif ~isnumeric(destInputs)||~isvector(destInputs)
                robolog('Destination inputs must be specified as a vector of integers.', 'ERR');
            end
             
            if numel(units)~=obj.nOutputs || ~isvector(units)
                robolog('Number of connected units must be equal to the number of output signals. %s has %d outputs; %d destination units were specified', 'ERR', obj.label, obj.nOutputs, numel(units));
            end
            
            % Check that destination makes basic sense
            destMax = cellfun(@(x)x.nInputs, units);
            if any(destInputs(:)>destMax(:))
                badone = find(destInputs(:)>destMax(:));
                robolog('Specified input exceeds allowed number of inputs.  \n%s has %d inputs, so you cannot connect to port %d.', 'ERR', units{badone}.label, units{badone}.nInputs, destInputs(badone));
            end
            if any(destInputs(:)<1)
                robolog('Input numbers must be 1 or greater', 'ERR');
            end
            
                
            for i=1:obj.nOutputs
                obj.connectOutput(units{i},i,destInputs(i));
            end
        end
        
        %> @brief write input buffer
        function writeInputBuffer(obj,sig,inputId)
            obj.inputBuffer{inputId} = sig;
        end
        
        %> @brief horizontal concatenation
        function newobj = horzcat(varargin)
            for jj = 1:nargin
                newobj{jj} = varargin{jj};
            end
        end
        
        %> @brief vertical concatenation
        function newobj = vertcat(varargin)
            for jj = 1:nargin
                newobj{jj} = varargin{jj};
            end
            newobj = newobj.';
        end
           
        %> @brief set parameters
        %> 
        %> Compare user-specified parameters to class properties.  Assign
        %> as many as possible, warn the user when default is being used
        %> and when they have specified properties the class does not have.
        %>
        %> For example, using Delay_v1, if the constructor is 
        %> @code
        %> function obj = Delay_v1(param)
        %>      setparams(obj, param);
        %> end
        %> @endcode
        %> Then the following code:
        %> @code
        %> goodparam = struct('delay', 100, 'mode', 'symbols');
        %> delay = Delay_v1(goodparam);
        %> @endcode
        %> returns no warnings, errors, etc.  This code, 
        %> @code
        %> weirdparam = struct('delay', 100, 'mode', 'symbols', 'puppies', 1e6);
        %> delay = Delay_v1(weirdparam);
        %> @endcode
        %> will warn the user that ther is no puppies property in the delay
        %> class.  If instead the constructor had been written
        %> @code
        %> function obj = Delay_v1(param)
        %>      setparams(obj, param, {}, {'draw'});
        %> end
        %> @endcode
        %> then 
        %> @code
        %> delay = Delay_v1(goodparam);
        %> @endcode
        %> would warn the user that nInputs, nOutputs, results, and label
        %> are set to the default values.  A better constructor would be
        %> @code
        %> function obj = Delay_v1(param)
        %>      setparams(obj, param, {'delay'});
        %> end
        %> @endcode
        %> because it will return an error if the user tries to build a
        %> delay without actually specifying the delay.  It will also warn
        %> the user if any other class-specific properties (mode, in this
        %> case) are set to default.
        %>
        %> @param params parameter structure to evaluate
        %> @param REQUIRED_PARAMS cell array of required parameter names (default empty)
        %> @param QUIET_PARAMS cell array of parameter names not to warn user about (default nInputs, nOutputs, results, label, draw)
        function setparams(obj,params,REQUIRED_PARAMS, QUIET_PARAMS)
            DEFAULT_QUIET_PARAMS = {'nInputs', 'nOutputs', 'results', 'label', 'draw'};
            if nargin<3, REQUIRED_PARAMS = {}; end
            if nargin<4
                QUIET_PARAMS = DEFAULT_QUIET_PARAMS;
            else
                QUIET_PARAMS = [QUIET_PARAMS DEFAULT_QUIET_PARAMS];
            end
            PROTECTED_NAMES = {'inputBuffer', 'nextNodes', 'destInputs'};
            %get cell array of params
            if isstruct(params)
                f = fieldnames(params);
            elseif iscell(params)
                f = params;     %Some units pass empty cell to setparams - this is not ideal, but not a huge problem
            else
                f = {};
            end
            
            %Check if required properties are specified
            reqm = ismember(REQUIRED_PARAMS,f);
            if ~isempty(reqm) && ~all(reqm)
                robolog('Required parameters %s were not passed.', 'ERR', strjoin(strcat('''',REQUIRED_PARAMS(~reqm),''''),', '));
            end
            
            % Remove protected properties
            [protected,protected_idx] = intersect(f,PROTECTED_NAMES);
            if ~isempty(protected)
                robolog('Protected class properties %s were removed from being assigned.', 'WRN', strjoin(strcat('''',protected,''''),', '), 'WRN');
            end
            xi2 = false(size(f)); xi2(protected_idx)=true;
            f = f(~xi2);
            
            % Find unused parameters
            props = properties(obj); props=props(:)';
            [fassign,ai,bi] = intersect(f,props);
            [~,~,ci] = intersect(QUIET_PARAMS,props);
            ai2 = false(size(f)); ai2(ai)=true; ai2=~ai2;
            bi2 = false(size(props)); bi2(bi)=true; bi2(ci)=true; bi2=~bi2;
            if any(ai2), robolog('Following properties: %s are not used by the class.', 'NFO0', strjoin(strcat('''',f(ai2),''''),', ')); end
            if any(bi2)
                robolog('The following properties use default value from %s (%s):', 'NFO0', obj.label, class(obj));
                defProp = props(bi2);
                mTxtL = max(cellfun(@(x) numel(x), defProp));
                for pri=1:numel(defProp)
                    prVal = obj.(defProp{pri});
                    if isnumeric(prVal) || islogical(prVal)
                        strVal = num2str(prVal);
                    elseif ischar(prVal)
                        strVal = prVal;
                    else
                        strVal = sprintf('Default value of type %s', class(prVal));
                    end
                    robolog(['%' num2str(mTxtL + 3) 's: %s'], 'NFO0', defProp{pri}, strVal);
                end
            end
            for i=1:numel(fassign)
                mp = findprop(obj,fassign{i});
                if strcmp(mp.SetAccess, 'public') % Assign only public properties
                    obj.(fassign{i}) = params.(fassign{i});
                else
                    robolog('Private property: ''%s'' not assigned.', 'NFO0', fassign{i});
                end
            end
        end
        
        %> @brief Show interactive GUI through unit_view-class
        function view(obj)
           unit_view(obj.nextNodes,obj.destInputs,obj.label);
        end
    end
end
        
