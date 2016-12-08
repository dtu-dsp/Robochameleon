%> @file biograph.m
%> @brief biograph replacement for toolbox compatibility
%>
%> @class biograph
%> @brief biograph replacement for toolbox compatibility
%>
%> 
%> Replaces the functions module uses to determine traversing order.
%>
%> Note, I'm not 100% sure that the input/output node ordering is correct -
%> it is definitely possible that this reverses the order.  I tested
%> at the output for one case, it it was correct, but I have not tested at
%> the input (I do not think we have any modules with multiple inputs), and
%> also I've noticed since this is kind of a fuzzy thing, how it acts seems
%> to depend a lot on what we put in.  So use at your own risk...
%>
%>
%> @author Molly Piels
%> @author Simone Gaiarin
%>
%> @version 1
classdef biograph < matlab.mixin.SetGet
    %biograph replacement class
    
    properties
        ArrowSize=8;
        CustomNodeDrawFcn=0;
        Description;
        EdgeCallbacks=@(edge)inspect(edge);
        EdgeFontSize=8;
        EdgeTextColor=[0 0 0];
        EdgeType = 'curved';
        Edges = [];
        ID;
        LayoutScale = 1;
        LayoutType = 'hierarchical';
        NodeAutoSize = 'on';
        NodeCallbacks = @(node)inspect(node);
        Nodes = [];
        Scale = 1;
        ShowArrows = 'on';
        ShowTextInNodes = 'label';
        ShowWeights = 'off';
        dg;
    end
    
    methods
        
        %> @brief Construct a biograph object
        %>
        %> @param dg Sparse matrix representing the graph
        function obj = biograph(dg)
            obj.dg = dg;
            
            [i,j,s] = find(dg);
            nodes = unique([i; j]);
            for jj=1:length(nodes)
                %load node
                obj.Nodes = [obj.Nodes, ...
                    struct('Color', [1 1 0.7], ...
                    'Description', [], ...
                    'FontSize', 9, ...
                    'LineColor', [0.3 0.3 1], ...
                    'LineWidth', 1, ...
                    'Position', [], ...
                    'Shape', 'box', ...
                    'Size', [10, 10], ...
                    'TextColor', [0 0 0], ...
                    'UserData', [], ...
                    'ID', sprintf('Node %d', nodes(jj)))];
                
                %load connections from each node
                idx = find(i==nodes(jj));
                for kk=1:length(idx)
                    obj.Edges = [obj.Edges, ...
                        struct('Description', [], ...
                        'ID', sprintf('Node %d -> Node %d', nodes(jj), j(idx(kk))), ...
                        'Label', [], ...
                        'LineColor', [0.7 0.7 0.7], ...
                        'LineWidth', 0.5, ...
                        'UserData', [], ...
                        'Weight', 1.0)];
                end
            end
        end
        
        %> @brief Search all the ancestors of the node
        %>
        %> @param dg Sparse matrix representing the graph 
        %> @param node Current node processed (column number)
        %>
        %> @retval ancestors Row vector whose elements equal to one are the parents of node
        function ancestors = findAncestors(obj, dg, node)
            n = size(dg, 1);
            ancestors = zeros(1,n);
            for i=find(dg(:, node).')
                % Update ancestors with the parents of the current node
                % and proceed to the recursive step. Leaf nodes returns 
                % an all zero vecotr
                ancestors = ancestors | dg(:,node).' | obj.findAncestors(dg, i);
            end
        end
        
        %> @brief Set node callback function
        %>
        %> Syntax: 
        %> @code 
        %> obj.set('NodeCallbacks', @(x)do_something(x));
        %> @endcode
        function obj = set.NodeCallbacks(obj, value)
            obj.NodeCallbacks = value;
        end
        
        %> @brief Topological sort 3
        %> 
        %> Use recursive approach using the sparse matrix representation of the graph
        function Layers = sort3(obj)
            n = size(obj.dg, 1);
            % If (i,j) is 1 i is an ancestor of j
            ancestorsMat = zeros(n);
            for i=1:n
                ancestorsMat(:,i) = obj.findAncestors(obj.dg, i);
            end
            
            % Sort node indices (first column) based on how many ancestors they have (second column)
            % The first column contains the sorted node indices
            nodesOrdering = sortrows([1:n; sum(ancestorsMat)].', 2).';

            % This ugly code just builds the output cell
            i = 1;
            x = 1;
            while i<=n
                j = i + 1;
                if i ~= n
                    % Put nodes with the same number of parents in the same row
                    while j<=n && (nodesOrdering(2,j) == nodesOrdering(2,i))
                        j = j+1;
                    end
                end
                Layers{x} = nodesOrdering(1,i:(j-1));
                i = j;
                x = x + 1;
            end
        end
        
        %> @brief Display biograph
        %> 
        %> Calls biograph::sort3
        function view(obj)
            order = sort3(obj);
            nLayers = numel(order);
            dy = 0.8/(nLayers-1);
            figure('Color', 'w', 'Tag', 'BioGraphTool');
            hg.biograph.hgAxes = axes('Visible', 'off', 'Position', [0 0 1 1]);
            
            %draw nodes
            for jj = 1:nLayers
                LayerVec = order{jj};
                dx = 0.9/numel(LayerVec);
                for kk=1:numel(LayerVec)
                    switch lower(obj.ShowTextInNodes)
                        case 'label'
                            if isfield(obj.Nodes(LayerVec(kk)), 'Label')
                                str2print = obj.Nodes(LayerVec(kk)).Label;
                            else
                                str2print = obj.Nodes(LayerVec(kk)).ID;
                            end
                        otherwise
                            str2print = obj.Nodes(LayerVec(kk)).ID;
                    end
                    obj.Nodes(LayerVec(kk)).Position = [0.05+(kk-0.5)*dx, 0.9-(jj-1)*dy];
                    t=text(0.05+(kk-0.5)*dx, 0.9-(jj-1)*dy, str2print, ...
                        'FontSize', obj.Nodes(LayerVec(kk)).FontSize, ...
                        'HorizontalAlignment', 'center', ...
                        'BackgroundColor', obj.Nodes(LayerVec(kk)).Color, ...
                        'EdgeColor', obj.Nodes(LayerVec(kk)).LineColor, ...
                        'UserData', obj.Nodes(LayerVec(kk)).UserData, ...
                        'Interpreter', 'none');
                    callbacktmp = @(x, y)obj.NodeCallbacks(x);      %callback functions must accept two arguments
                    set(t, 'ButtonDownFcn', callbacktmp);
                end
            end
            
            nEdges = numel(obj.Edges);
            nNodes = numel(obj.Nodes);
            for jj=1:nEdges
                idx_ctr = strfind(obj.Edges(jj).ID, '->');
                nodestart =  obj.Edges(jj).ID(1:idx_ctr-2);
                nodestop = obj.Edges(jj).ID(idx_ctr+3:end);
                for kk=1:nNodes
                    if strcmp(obj.Nodes(kk).ID, nodestart)
                        pos_0 = obj.Nodes(kk).Position;
                    elseif strcmp(obj.Nodes(kk).ID, nodestop)
                        pos_1 = obj.Nodes(kk).Position;
                    end
                end
                
                h=annotation('arrow', [pos_0(1) pos_1(1)], [pos_0(2) pos_1(2)]);
                h.Color = obj.Edges(jj).LineColor;
                h.LineWidth = obj.Edges(jj).LineWidth;
            end
            
        end
    end
end
    
