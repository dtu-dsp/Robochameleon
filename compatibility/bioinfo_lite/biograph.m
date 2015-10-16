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
%>
%> @version 1
classdef biograph
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
    end
    
    methods
        
        %constructor
        function obj = biograph(dg)
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
        
        %> @brief topological sort 1
        %> 
        %> Starts from head (do not use)
        function Layers = sort(obj)
            %count
            Nnodes = numel(obj.Nodes);
            strikeout = [];
            
            %find initial vertices
            Layer0 = [];
            for jj=1:Nnodes
                if isempty(strfind([obj.Edges.ID], sprintf('-> %s', obj.Nodes(jj).ID)))
                    Layer0 = [Layer0, jj];
                    strikeout = [strikeout, jj];
                end
            end
            
            %find subsequent layers
            Layers = {Layer0};
            Layer_counter = 1;
            while numel(strikeout)<Nnodes
                Layer_curr = [];
                strike_curr = [];
                Layer_last = cell2mat(Layers(Layer_counter));
                %sweep over all nodes in last layer
                for kk=1:numel(Layer_last)
                    %sweep over remaining nodes
                    for jj=1:Nnodes
                        if ~any(jj==strikeout)
                            %see if node in previous layer points to this node
                            if ~isempty(strfind([obj.Edges.ID 'N'], sprintf('%s -> %sN', obj.Nodes(Layer_last(kk)).ID, obj.Nodes(jj).ID)))
                                Layer_curr = [Layer_curr, jj];
                                strike_curr = [strike_curr, jj];
                            end
                        end
                    end
                end
                %consolidate vectors, update
                strikeout = [strikeout, unique(strike_curr)];
                Layer_curr = unique(Layer_curr);
                Layer_counter = Layer_counter+1;
                Layers{Layer_counter} = Layer_curr;
            end
            
        end
        
        %> @brief topological sort 2
        %> 
        %> Starts from tail, splits top layer in case module has an input.
        function Layers = sort2(obj)
            %count
            Nnodes = numel(obj.Nodes);
            strikeout = [];
            
            %find initial vertices
            LayerEnd = [];
            for jj=1:Nnodes
                if isempty(strfind([obj.Edges.ID], sprintf('%s ->', obj.Nodes(jj).ID)))
                    LayerEnd = [LayerEnd, jj];
                    strikeout = [strikeout, jj];
                end
            end
            
            %find subsequent layers
            Layers = {LayerEnd};
            Layer_counter = 1;
            while numel(strikeout)<Nnodes
                Layer_curr = [];
                strike_curr = [];
                Layer_last = cell2mat(Layers(Layer_counter));
                %sweep over all nodes in last layer
                for kk=1:numel(Layer_last)
                    %sweep over remaining nodes
                    for jj=1:Nnodes
                        if ~any(jj==strikeout)
                            %see if node in previous layer points to this node
                            if ~isempty(strfind([obj.Edges.ID 'N'], sprintf('%s -> %sN', obj.Nodes(jj).ID, obj.Nodes(Layer_last(kk)).ID)))
                                Layer_curr = [Layer_curr, jj];
                                strike_curr = [strike_curr, jj];
                            end
                        end
                    end
                end
                %consolidate vectors, update
                strikeout = [strikeout, unique(strike_curr)];
                Layer_curr = unique(Layer_curr);
                Layer_counter = Layer_counter+1;
                Layers{Layer_counter} = Layer_curr;
            end
            
            %re-order top->bottom
            Layers = fliplr(Layers);
            
            %Split first layer if necessary
            Layer_check = cell2mat(Layers(1));
            if numel(Layer_check)>1
                Layer0 = [];
                Layer1 = [];
                for jj=1:numel(Layer_check)
                    if isempty(strfind([obj.Edges.ID], sprintf('-> %s', obj.Nodes(Layer_check(jj)).ID)))
                        Layer0 = [Layer0, Layer_check(jj)];
                    else
                        Layer1 = [Layer1, Layer_check(jj)];
                    end
                end
                Layers = {Layer0 Layer1 Layers{2:end}};
            end
        end
        
        %> @brief Display biograph
        %> 
        %> Calls biograph::sort2
        function view(obj)
            order = sort2(obj);
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
                    text(0.05+(kk-0.5)*dx, 0.9-(jj-1)*dy, str2print, ...
                        'FontSize', obj.Nodes(LayerVec(kk)).FontSize, ...
                        'HorizontalAlignment', 'center', ...
                        'BackgroundColor', obj.Nodes(LayerVec(kk)).Color, ...
                        'EdgeColor', obj.Nodes(LayerVec(kk)).LineColor, ...
                        'Interpreter', 'none');
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
    
