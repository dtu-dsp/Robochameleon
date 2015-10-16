classdef GridFlex < uix.Grid
    %uix.GridFlex  Flexible grid
    %
    %  b = uix.GridFlex(p1,v1,p2,v2,...) constructs a flexible grid and
    %  sets parameter p1 to value v1, etc.
    %
    %  A grid lays out contents from top to bottom and left to right.
    %  Users can resize contents by dragging the dividers.
    %
    %  See also: uix.HBoxFlex, uix.VBoxFlex, uix.Grid
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 999 $ $Date: 2014-10-01 14:55:26 -0400 (Wed, 01 Oct 2014) $
    
    properties( Access = public, Dependent, AbortSet )
        DividerMarkings % divider markings [on|off]
    end
    
    properties( Access = private )
        RowDividers = uix.Divider.empty( [0 1] )
        ColumnDividers = uix.Divider.empty( [0 1] )
        FrontDivider % front divider
        DividerMarkings_ = 'on' % backing for DividerMarkings
        LocationObserver % location observer
        MousePressListener = event.listener.empty( [0 0] ) % mouse press listener
        MouseReleaseListener = event.listener.empty( [0 0] ) % mouse release listener
        MouseMotionListener = event.listener.empty( [0 0] ) % mouse motion listener
        ActiveDivider = 0 % active divider index
        ActiveDividerPosition = [NaN NaN NaN NaN] % active divider position
        MousePressLocation = [NaN NaN] % mouse press location
        Pointer = 'unset' % mouse pointer
        OldPointer = 0 % old pointer
        BackgroundColorListener % background color listener
    end
    
    methods
        
        function obj = GridFlex( varargin )
            %uix.GridFlex  Flexible grid constructor
            %
            %  b = uix.GridFlex() constructs a flexible grid.
            %
            %  b = uix.GridFlex(p1,v1,p2,v2,...) sets parameter p1 to value
            %  v1, etc.
            
            % Call superclass constructor
            obj@uix.Grid()
            
            % Create front divider
            frontDivider = uix.Divider( 'Parent', obj, ...
                'Orientation', 'vertical', ...
                'BackgroundColor', obj.BackgroundColor * 0.75, ...
                'Visible', 'off' );
            
            % Create observers and listeners
            locationObserver = uix.LocationObserver( obj );
            backgroundColorListener = event.proplistener( obj, ...
                findprop( obj, 'BackgroundColor' ), 'PostSet', ...
                @obj.onBackgroundColorChange );
            
            % Store properties
            obj.FrontDivider = frontDivider;
            obj.LocationObserver = locationObserver;
            obj.BackgroundColorListener = backgroundColorListener;
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
    methods
        
        function value = get.DividerMarkings( obj )
            
            value = obj.DividerMarkings_;
            
        end % get.DividerMarkings
        
        function set.DividerMarkings( obj, value )
            
            % Check
            assert( ischar( value ) && any( strcmp( value, {'on','off'} ) ), ...
                'uix:InvalidArgument', ...
                'Property ''DividerMarkings'' must be ''on'' or ''off'.' )
            
            % Set
            obj.DividerMarkings_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.DividerMarkings
        
    end % accessors
    
    methods( Access = protected )
        
        function onMousePress( obj, ~, ~ )
            %onMousePress  Handler for WindowMousePress events
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            % Check whether mouse is over a divider
            pointerLocation = ROOT.PointerLocation;
            point = pointerLocation - ...
                obj.LocationObserver.Location(1:2) + [1 1];
            cRowPositions = get( obj.RowDividers, {'Position'} );
            rowPositions = vertcat( cRowPositions{:} );
            [tfr, locr] = uix.inrectangle( point, rowPositions );
            cColumnPositions = get( obj.ColumnDividers, {'Position'} );
            columnPositions = vertcat( cColumnPositions{:} );
            [tfc, locc] = uix.inrectangle( point, columnPositions );
            if tfr
                loc = locr;
                divider = obj.RowDividers(locr);
            elseif tfc
                loc = -locc;
                divider = obj.ColumnDividers(locc);
            else
                return
            end
            
            % Capture state at button down
            obj.ActiveDivider = loc;
            obj.ActiveDividerPosition = divider.Position;
            obj.MousePressLocation = pointerLocation;
            
            % Activate divider
            frontDivider = obj.FrontDivider;
            frontDivider.Position = divider.Position;
            frontDivider.Orientation = divider.Orientation;
            frontDivider.Parent = [];
            frontDivider.Parent = obj;
            divider.Visible = 'off';
            frontDivider.Visible = 'on';
            
        end % onMousePress
        
        function onMouseRelease( obj, ~, ~ )
            %onMousePress  Handler for WindowMouseRelease events
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            % Compute new positions
            loc = obj.ActiveDivider;
            contents = obj.Contents_;
            if loc > 0
                delta = ROOT.PointerLocation(2) - obj.MousePressLocation(2);
                ih = loc;
                jh = loc + 1;
                ic = loc;
                jc = loc + 1;
                divider = obj.RowDividers(loc);
                oldPixelHeights = [contents(ic).Position(4); contents(jc).Position(4)];
                minimumHeights = obj.MinimumHeights_(ih:jh,:);
                if delta < 0 % limit to minimum distance from lower neighbor
                    delta = max( delta, minimumHeights(2) - oldPixelHeights(2) );
                else % limit to minimum distance from upper neighbor
                    delta = min( delta, oldPixelHeights(1) - minimumHeights(1) );
                end
                oldHeights = obj.Heights_(loc:loc+1);
                newPixelHeights = oldPixelHeights - delta * [1;-1];
                if oldHeights(1) < 0 && oldHeights(2) < 0 % weight, weight
                    newHeights = oldHeights .* newPixelHeights ./ oldPixelHeights;
                elseif oldHeights(1) < 0 && oldHeights(2) >= 0 % weight, pixels
                    newHeights = [oldHeights(1) * newPixelHeights(1) / ...
                        oldPixelHeights(1); newPixelHeights(2)];
                elseif oldHeights(1) >= 0 && oldHeights(2) < 0 % pixels, weight
                    newHeights = [newPixelHeights(1); oldHeights(2) * ...
                        newPixelHeights(2) / oldPixelHeights(2)];
                else % sizes(1) >= 0 && sizes(2) >= 0 % pixels, pixels
                    newHeights = newPixelHeights;
                end
                obj.Heights_(loc:loc+1) = newHeights;
            elseif loc < 0
                delta = ROOT.PointerLocation(1) - obj.MousePressLocation(1);
                iw = -loc;
                jw = -loc + 1;
                r = numel( obj.Heights_ );
                ic = r * (-loc-1) + 1;
                jc = r * -loc + 1;
                divider = obj.ColumnDividers(iw);
                oldPixelWidths = [contents(ic).Position(3); contents(jc).Position(3)];
                minimumWidths = obj.MinimumWidths_(iw:jw,:);
                if delta < 0 % limit to minimum distance from left neighbor
                    delta = max( delta, minimumWidths(1) - oldPixelWidths(1) );
                else % limit to minimum distance from right neighbor
                    delta = min( delta, oldPixelWidths(2) - minimumWidths(2) );
                end
                oldWidths = obj.Widths_(iw:jw);
                newPixelWidths = oldPixelWidths + delta * [1;-1];
                if oldWidths(1) < 0 && oldWidths(2) < 0 % weight, weight
                    newWidths = oldWidths .* newPixelWidths ./ oldPixelWidths;
                elseif oldWidths(1) < 0 && oldWidths(2) >= 0 % weight, pixels
                    newWidths = [oldWidths(1) * newPixelWidths(1) / ...
                        oldPixelWidths(1); newPixelWidths(2)];
                elseif oldWidths(1) >= 0 && oldWidths(2) < 0 % pixels, weight
                    newWidths = [newPixelWidths(1); oldWidths(2) * ...
                        newPixelWidths(2) / oldPixelWidths(2)];
                else % sizes(1) >= 0 && sizes(2) >= 0 % pixels, pixels
                    newWidths = newPixelWidths;
                end
                obj.Widths_(iw:jw) = newWidths;
            else
                return
            end
            
            % Deactivate divider
            obj.FrontDivider.Visible = 'off';
            divider.Visible = 'on';
            
            % Reset state at button down
            obj.ActiveDivider = 0;
            obj.ActiveDividerPosition = [NaN NaN NaN NaN];
            obj.MousePressLocation = [NaN NaN];
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % onMouseRelease
        
        function onMouseMotion( obj, source, ~ )
            %onMouseMotion  Handler for WindowMouseMotion events
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            loc = obj.ActiveDivider;
            contents = obj.Contents_;
            if loc == 0 % hovering, update pointer
                point = ROOT.PointerLocation - ...
                    obj.LocationObserver.Location(1:2) + [1 1];
                cRowPositions = get( obj.RowDividers, {'Position'} );
                rowPositions = vertcat( cRowPositions{:} );
                tfr = uix.inrectangle( point, rowPositions );
                cColumnPositions = get( obj.ColumnDividers, {'Position'} );
                columnPositions = vertcat( cColumnPositions{:} );
                tfc = uix.inrectangle( point, columnPositions );
                oldPointer = obj.OldPointer;
                newPointer = tfr - ( tfc && ~tfr );
                if oldPointer == -1 && newPointer == 1
                    source.Pointer = 'top';
                elseif oldPointer == 1 && newPointer == -1
                    source.Pointer = 'left';
                elseif oldPointer ~= 0 && newPointer == 0
                    source.Pointer = obj.Pointer; % restore
                    obj.Pointer = 'unset'; % unset
                elseif oldPointer == 0 && newPointer == -1
                    obj.Pointer = source.Pointer; % set
                    source.Pointer = 'left';
                elseif oldPointer == 0 && newPointer == 1
                    obj.Pointer = source.Pointer; % set
                    source.Pointer = 'top';
                end
                obj.OldPointer = newPointer;
            elseif loc > 0 % dragging row divider
                delta = ROOT.PointerLocation(2) - obj.MousePressLocation(2);
                ih = loc;
                jh = loc + 1;
                ic = loc;
                jc = loc + 1;
                oldPixelHeights = [contents(ic).Position(4); contents(jc).Position(4)];
                minimumHeights = obj.MinimumHeights_(ih:jh,:);
                if delta < 0 % limit to minimum distance from lower neighbor
                    delta = max( delta, minimumHeights(2) - oldPixelHeights(2) );
                else % limit to minimum distance from upper neighbor
                    delta = min( delta, oldPixelHeights(1) - minimumHeights(1) );
                end
                obj.FrontDivider.Position = ...
                    obj.ActiveDividerPosition + [0 delta 0 0];
            else % loc < 0, dragging column divider
                delta = ROOT.PointerLocation(1) - obj.MousePressLocation(1);
                iw = -loc;
                jw = -loc + 1;
                r = numel( obj.Heights_ );
                ic = r * (-loc-1) + 1;
                jc = r * -loc + 1;
                oldPixelWidths = [contents(ic).Position(3); contents(jc).Position(3)];
                minimumWidths = obj.MinimumWidths_(iw:jw,:);
                if delta < 0 % limit to minimum distance from left neighbor
                    delta = max( delta, minimumWidths(1) - oldPixelWidths(1) );
                else % limit to minimum distance from right neighbor
                    delta = min( delta, oldPixelWidths(2) - minimumWidths(2) );
                end
                obj.FrontDivider.Position = ...
                    obj.ActiveDividerPosition + [delta 0 0 0];
            end
            
        end % onMouseMotion
        
        function onBackgroundColorChange( obj, ~, ~ )
            %onBackgroundColorChange  Handler for BackgroundColor changes
            
            backgroundColor = obj.BackgroundColor;
            highlightColor = min( [backgroundColor / 0.75; 1 1 1] );
            shadowColor = max( [backgroundColor * 0.75; 0 0 0] );
            rowDividers = obj.RowDividers;
            for ii = 1:numel( rowDividers )
                rowDivider = rowDividers(ii);
                rowDivider.BackgroundColor = backgroundColor;
                rowDivider.HighlightColor = highlightColor;
                rowDivider.ShadowColor = shadowColor;
            end
            columnDividers = obj.ColumnDividers;
            for jj = 1:numel( columnDividers )
                columnDivider = columnDividers(jj);
                columnDivider.BackgroundColor = backgroundColor;
                columnDivider.HighlightColor = highlightColor;
                columnDivider.ShadowColor = shadowColor;
            end
            frontDivider = obj.FrontDivider;
            frontDivider.BackgroundColor = shadowColor;
            
        end % onBackgroundColorChange
        
    end % event handlers
    
    methods( Access = protected )
        
        function redraw( obj )
            %redraw  Redraw contents
            %
            %  c.redraw() redraws the container c.
            
            % Call superclass method
            redraw@uix.Grid( obj )
            
            % Create or destroy column dividers
            b = numel( obj.ColumnDividers ); % current number of dividers
            c = max( [numel( obj.Widths_ )-1 0] ); % required number of dividers
            if b < c % create
                for ii = b+1:c
                    columnDivider = uix.Divider( 'Parent', obj, ...
                        'Orientation', 'vertical', ...
                        'BackgroundColor', obj.BackgroundColor );
                    obj.ColumnDividers(ii,:) = columnDivider;
                end
                % Bring front divider to the front
                frontDivider = obj.FrontDivider;
            elseif b > c % destroy
                % Destroy dividers
                delete( obj.ColumnDividers(c+1:b,:) )
                obj.ColumnDividers(c+1:b,:) = [];
            end
            
            % Create or destroy row dividers
            q = numel( obj.RowDividers ); % current number of dividers
            r = max( [numel( obj.Heights_ )-1 0] ); % required number of dividers
            if q < r % create
                for ii = q+1:r
                    columnDivider = uix.Divider( 'Parent', obj, ...
                        'Orientation', 'horizontal', ...
                        'BackgroundColor', obj.BackgroundColor );
                    obj.RowDividers(ii,:) = columnDivider;
                end
                % Bring front divider to the front
                frontDivider = obj.FrontDivider;
                frontDivider.Parent = [];
                frontDivider.Parent = obj;
            elseif q > r % destroy
                % Destroy dividers
                delete( obj.RowDividers(r+1:q,:) )
                obj.RowDividers(r+1:q,:) = [];
            end
            
            % Compute container bounds
            bounds = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            
            % Retrieve size properties
            widths = obj.Widths_;
            minimumWidths = obj.MinimumWidths_;
            heights = obj.Heights_;
            minimumHeights = obj.MinimumHeights_;
            padding = obj.Padding_;
            spacing = obj.Spacing_;
            
            % Compute row divider positions
            xRowPositions = [padding + 1, max( bounds(3) - 2 * padding, 1 )];
            xRowPositions = repmat( xRowPositions, [r 1] );
            yRowSizes = uix.calcPixelSizes( bounds(4), heights, ...
                minimumHeights, padding, spacing );
            yRowPositions = [bounds(4) - cumsum( yRowSizes(1:r,:) ) - padding - ...
                spacing * transpose( 1:r ) + 1, repmat( spacing, [r 1] )];
            rowPositions = [xRowPositions(:,1), yRowPositions(:,1), ...
                xRowPositions(:,2), yRowPositions(:,2)];
            
            % Compute column divider positions
            xColumnSizes = uix.calcPixelSizes( bounds(3), widths, ...
                minimumWidths, padding, spacing );
            xColumnPositions = [cumsum( xColumnSizes(1:c,:) ) + padding + ...
                spacing * transpose( 0:c-1 ) + 1, repmat( spacing, [c 1] )];
            yColumnPositions = [padding + 1, max( bounds(4) - 2 * padding, 1 )];
            yColumnPositions = repmat( yColumnPositions, [c 1] );
            columnPositions = [xColumnPositions(:,1), yColumnPositions(:,1), ...
                xColumnPositions(:,2), yColumnPositions(:,2)];
            
            % Position row dividers
            for ii = 1:r
                rowDivider = obj.RowDividers(ii);
                rowDivider.Position = rowPositions(ii,:);
                switch obj.DividerMarkings_
                    case 'on'
                        rowDivider.Markings = cumsum( xColumnSizes ) + ...
                            spacing * transpose( 0:c ) - xColumnSizes / 2;
                    case 'off'
                        rowDivider.Markings = zeros( [0 1] );
                end
            end
            
            % Position column dividers
            for ii = 1:c
                columnDivider = obj.ColumnDividers(ii);
                columnDivider.Position = columnPositions(ii,:);
                switch obj.DividerMarkings_
                    case 'on'
                        columnDivider.Markings = cumsum( yRowSizes ) + ...
                            spacing * transpose( 0:r ) - yRowSizes / 2;
                    case 'off'
                        columnDivider.Markings = zeros( [0 1] );
                end
            end
            
            % Update pointer
            obj.onMouseMotion( ancestor( obj, 'figure' ), [] )
            
        end % redraw
        
        function unparent( obj, oldAncestors )
            %unparent  Unparent container
            %
            %  c.unparent(a) unparents the container c from the ancestors
            %  a.
            
            % Restore figure pointer
            if ~isempty( oldAncestors ) && ...
                    isa( oldAncestors(1), 'matlab.ui.Figure' )
                oldFigure = oldAncestors(1);
                oldPointer = obj.OldPointer;
                if oldPointer ~= 0
                    oldFigure.Pointer = obj.Pointer;
                    obj.Pointer = 'unset';
                    obj.OldPointer = 0;
                end
            end
            
            % Call superclass method
            unparent@uix.Container( obj, oldAncestors )
            
        end % unparent
        
        function reparent( obj, oldAncestors, newAncestors )
            %reparent  Reparent container
            %
            %  c.reparent(a,b) reparents the container c from the ancestors
            %  a to the ancestors b.
            
            % Refresh location observer
            locationObserver = uix.LocationObserver( [newAncestors; obj] );
            obj.LocationObserver = locationObserver;
            
            % Refresh mouse listeners if figure has changed
            if isempty( oldAncestors ) || ...
                    ~isa( oldAncestors(1), 'matlab.ui.Figure' )
                oldFigure = gobjects( [0 0] );
            else
                oldFigure = oldAncestors(1);
            end
            if isempty( newAncestors ) || ...
                    ~isa( newAncestors(1), 'matlab.ui.Figure' )
                newFigure = gobjects( [0 0] );
            else
                newFigure = newAncestors(1);
            end
            if ~isequal( oldFigure, newFigure )
                if isempty( newFigure )
                    mousePressListener = event.listener.empty( [0 0] );
                    mouseReleaseListener = event.listener.empty( [0 0] );
                    mouseMotionListener = event.listener.empty( [0 0] );
                else
                    mousePressListener = event.listener( newFigure, ...
                        'WindowMousePress', @obj.onMousePress );
                    mouseReleaseListener = event.listener( newFigure, ...
                        'WindowMouseRelease', @obj.onMouseRelease );
                    mouseMotionListener = event.listener( newFigure, ...
                        'WindowMouseMotion', @obj.onMouseMotion );
                end
                obj.MousePressListener = mousePressListener;
                obj.MouseReleaseListener = mouseReleaseListener;
                obj.MouseMotionListener = mouseMotionListener;
            end
            
            % Call superclass method
            reparent@uix.Container( obj, oldAncestors, newAncestors )
            
            % Update pointer
            obj.onMouseMotion( ancestor( obj, 'figure' ), [] )
            
        end % reparent
        
    end % template methods
    
end % classdef