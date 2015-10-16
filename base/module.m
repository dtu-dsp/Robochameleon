%> @file module.m
%> @brief Superclass: collection/sequence of unit
%>
%> @class module
%> @brief Superclass: collection/sequence of unit
%> 
%> @ingroup base
%>
%> Modules are used to encapsulate multiple units.  If you have a sequence 
%> of units/operations that is more or less fixed (e.g. the standard DSP 
%> chain is IQ imbalance -> CD compensation -> Retiming -> Equalization ->
%> Carrier recovery.  It would be reasonable to want a function block
%> that just did all this DSP, and that function block would be a module.
%> A module is a class with one function, the constructor, specified.
%>
%> For example:
%> @code
%> classdef MyDSPModule_v1 < module
%>     properties
%>       nInputs = 1; % Number of input arguments
%>       nOutputs = 1; % Number of output arguments    
%>     end
%>     methods
%>      function obj = MyDSPModule_v1(param)
%>          %Construct components
%>          IQ = QuadratureImbalanceCompensation_v1;
%>          CD = CDCompensation_v1(param.CD);
%>          ...
%>          CR = DDPLL_v1(param.crm);
%>
%>          %Connect everything          
%>          obj.connectInputs({IQ}, 1); %external connections on input
%>          IQ.connectOutputs(CD, 1); %IQ imbalance -> CD compensation
%>          ... 
%>          CR.connectOutputs(obj.outputBuffer,1); %external connections at output
%>
%>          %This line is required in constructor
%>          exportModule(obj);
%>      end
%>     end
%> end
%> @endcode
%>
%> Modules inherit from unit, thus module.traverse, module.connectOutputs,
%> and module.connectOutput are valid function calls.  For example:
%> @code
%> %Get some data - this is not a real function, imagine received_signal is some 
%> %signal_interface we want to demodulate.
%> received_signal = LoadTrace(filename);   
%>
%> %construct object with some parameters (assume specified elsewhere)
%> demodulator = MyDSPModule_v1(DSPparams);
%>
%> %run code
%> demodulated_signal = demodulator.traverse(received_signal);
%> @endcode
%>
%> @see unit
%>
%> @author Robert Borkowski
%> @version 1
classdef module < unit
    
    properties (Abstract)
        %> Number of input arguments (required)
        nInputs; 
        %> Number of output arguments (required)
        nOutputs; 
    end
            
    properties (GetAccess=public,SetAccess=private,Hidden=false) % Set Hidden=true afterwards
        %> Cell array of units in module
        internalUnits = {};
        %> Order in which to traverse units
        traversingOrder = [];
    end
    
    properties (GetAccess=protected,SetAccess=private,Hidden=false) % Set Hidden=true afterwards
        destInternalUnits = {};
        destInternalInputs = [];
    end
    
    properties (GetAccess=protected,SetAccess=protected)
        %> Where output signal is stored
        outputBuffer; % initialized to be a sink with obj.nOutputs inputs
    end
    
    methods (Access=private)
        
        %> @brief Determine order in which to traverse units
        %>
        %> Create a "linked list like" graph, and display if obj.draw is
        %> true
        function createGraphOrdering(obj)
            N = numel(obj.internalUnits);
            % Traverse all internal units sequentially to discover graph structure
            UIDs = cell(N,1);
            for i=1:numel(obj.internalUnits)
                UIDs{i} = obj.internalUnits{i}.ID;
            end
            
            dg = logical(sparse(N,N));
            labels = cell(N,1);
            for i=1:N
%                 tmp = obj.internalUnits{i};
%                 for j=1:tmp.nOutputs
%                     nextNodeID = obj.internalUnits{i}.nextNodes{j}.ID;
                for nextNode = obj.internalUnits{i}.nextNodes
                    nextNodeID = nextNode{:}.ID;
                    k = find(cellfun(@(UID)isequal(nextNodeID,UID),UIDs));
                    if numel(k)>1
                        error('Something is wrong. Should return just one or zero match. Is it a DAG?');
                    end
                    dg(i,k) = true;
                end
                labels{i} = obj.internalUnits{i}.label;
            end
            
            if obj.draw
                if isempty(dg) % no edges
                    warning('Module %s encloses no units. No graph will be drawn.',obj.label);
                elseif isscalar(dg) % one edge
                    warning('Module %s encloses only one unit. No graph will be drawn.',obj.label);
                    obj.traversingOrder = 1;
                else % more than one edge
                    bg = biograph(dg);
                    bg.ShowTextInNodes = 'Label';
                    for i=1:N, bg.Nodes(i).Label = labels{i}; end
                    
                    % Set biograph name
%                     hg = biograph.bggui(bg);
%                     set(get(hg.biograph.hgAxes,'parent'),'Name',obj.label);
                    view(bg);
                    handles = allchild(0);
                    hg = handles(1);
                    hg.Name = obj.label;
                   
%                     f = figure('Name',obj.label);
%                     copyobj(hg.biograph.hgAxes,f);
%                     close(hg.hgFigure);

%                     graphViz4Matlab('-adjMat',dg,'-nodeLabels',labels,'-layout',Treelayout);
                    
                end
            end
            obj.traversingOrder = graphtopoorder(sparse(dg)); % Doesn't work for one vertex
        end
        
    end
    
    
    
    methods (Access=protected)
        
        %> @brief Construct module
        %>
        %> Important.  Must be called during (at end of) constructor.
        function exportModule(obj,varargin)
            if isempty(varargin) % Automatic export
                vars = evalin('caller','who'); % Get variables from the caller
                vars(strcmp(inputname(1),vars)) = []; % Remove from the export list the module itself
%                 isunit = cellfun(@(v)evalin('caller',['inherits_from(' v ',''unit'')']),vars)
                % For some reason, the line above doesn't work and we need
                % following 4 lines
                isunit = false(size(vars)); % Check which variables inherit after unit
                for i=1:numel(vars)
                    isunit(i) = evalin('caller',['inherits_from(' vars{i} ',''unit'')']);
                end
                if ~any(isunit) % If no units found, show a warning
                    warning('Module does not enclose any unit. To manually export module use exportModule(obj,unit1,unit2,...).');
                else % If there are units to export, call exportModule with appropriate arguments
                    evalin('caller',['exportModule(obj,' strjoin(vars(isunit)',',') ');']);
                end
            else % Manual export / second call of automatic export
                if all(cellfun(@(o)inherits_from(o,'unit'),varargin))
                    obj.internalUnits = varargin;
                end
                createGraphOrdering(obj);
            end
        end
        
        %> @brief Connect input signal to internal unit(s)
        %>
        %> For modules with nInputs >= 1, the input signal must be routed
        %> to the correct internal unit or units.  Both the name of the
        %> unit and which of its inputs the signal should be attached to must
        %> be specified.  Syntax is the same as unit.connectOutputs.
        %>
        %> @param destInternalUnits cell array of internal units to connect to
        %> @param destInternalInputs numeric array specifying which input on each unit to connect to
        %> 
        %> @see unit.connectOutputs
        function connectInputs(obj,destInternalUnits,destInternalInputs)
            %TODO error checking, etc.
            obj.destInternalUnits = destInternalUnits;
            obj.destInternalInputs = destInternalInputs;
        end
        
%         function connectInternalOutputs(obj,srcInternalUnits,destExternalOutputs)
%             %TODO error checking, etc.
%             for i=1:obj.nOutputs
%                 srcInternalUnits{i}.connectOutput(obj.outputBuffer,i,destExternalOutputs(i));
%             end
%         end
    end
    
    
    
    methods (Access=public)
        
        %> @brief Create sink for internal output buffers
        function obj = module
            % Create sink for internal output buffers
            obj.outputBuffer = sink(obj.nOutputs);
        end

        %> @brief Traverse function for modules
        %>
        %> @param varargin input signal
        function varargout = traverse(obj,varargin)
            % Rewrite internal buffers to appropriate objects
            for i=1:obj.nInputs
                %FIXME when there's only one obj.destInternalUnits it must
                %be also packaged into cell array. Otherwise this line will
                %fail with "Cell contents reference from a non-cell array
                %object."
                % Ensure that in a call obj.connectInputs(units,no) units
                % is always a cell array of units.
                writeInputBuffer(obj.destInternalUnits{i},varargin{i},obj.destInternalInputs(i));
            end

            for i=obj.traversingOrder
                traverseNode(obj.internalUnits{i});
            end
            [varargout{1:obj.nOutputs}] = readBuffer(obj.outputBuffer);
        end        
    end
    
end