%> @file module_view.m
%> @brief Superclass: graphical interface for units
%>
%> @class module_view
%> @brief Superclass: graphical interface for units
%> 
%> This class creates the graphical interface and graphs which
%> enables the user to navigate through the modules and units.
%> In order to also view units the debugMode is supposed to be turned on.
%> @code
%> setpref('robochameleon','debugMode',true);
%> @endcode
%>
%> @author Rasmus Jones
%> @version 1
classdef module_view   
    properties(GetAccess=private,SetAccess=private,Hidden)
        %> Struct holding information necessary to construct the graph
        biograph_struct;
        %> Cell-array holding the units if this module
        internalUnits;
        %> Label of the module
        label;
    end

    methods (Access=public)
        function obj=module_view(biograph_struc,internalUnits,label)
           % Setter
           obj.biograph_struct    = biograph_struc;
           obj.internalUnits      = internalUnits;
           obj.label              = label;
           
           % Create and show biograph
           obj.createBiograph();
        end
        
        %> @brief Callback function when clicked on a block in the graph
        %>
        %> Enter a unit/module
        %>
        function node_callback(obj,node)
            obj.internalUnits{node.UserData}.view();        
        end
    end
    
    methods (Access=private)
        %> @brief Created the biograph
        %>
        %> Creates a "linked list like" graph, and displays it,
        %> called in the contructor
        %>
        function createBiograph(obj)
           if isempty(obj.biograph_struct.dg) % no edges
                warning('Module %s encloses no units. No graph will be drawn.',obj.biograph_struct.label);
            elseif isscalar(obj.biograph_struct.dg) % one edge
                warning('Module %s encloses only one unit. No graph will be drawn.',obj.biograph_struct.label);
            else % more than one edge
                bg = biograph(obj.biograph_struct.dg);
                set(bg, 'NodeCallbacks', @(node)obj.node_callback(node))
                bg.ShowTextInNodes = 'Label';
                N = numel(obj.internalUnits);
                for i=1:N
                    bg.Nodes(i).Label = obj.biograph_struct.labels{i};
                    bg.Nodes(i).Description = '';
                    bg.Nodes(i).UserData = i;                    
%                     if(obj.internalUnits{i}.debugMode)
%                         bg.Nodes(i).Shape = 'house';
%                     end
                    classes = superclasses(obj.internalUnits{i});
                    switch classes{1}
                        case 'unit' 
                            bg.Nodes(i).Color = [1 1 1];
                        case 'module'
                            bg.Nodes(i).Color = [200 200 200]/255;
                    end
                end
                view(bg);
                handles = allchild(0);
                hg = handles(1);
                hg.Name = obj.label;                                       
            end
        end        
    end    
end

