classdef TabPanel < uix.Container
    %uix.TabPanel  Tab panel
    %
    %  p = uix.TabPanel(p1,v1,p2,v2,...) constructs a tab panel and sets
    %  parameter p1 to value v1, etc.
    %
    %  A tab panel shows one of its contents and hides the others according
    %  to which tab is selected.
    %
    %  From R2014b, MATLAB provides uitabgroup and uitab as standard
    %  components.  Consider using uitabgroup and uitab for new code if
    %  these meet your requirements.
    %
    %  See also: uitabgroup, uitab, uix.CardPanel
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 992 $ $Date: 2014-09-29 04:20:51 -0400 (Mon, 29 Sep 2014) $
    
    properties( Access = public, Dependent, AbortSet )
        FontAngle % font angle
        FontName % font name
        FontSize % font size
        FontWeight % font weight
        FontUnits % font weight
        ForegroundColor % tab text color [RGB]
        HighlightColor % border highlight color [RGB]
        ShadowColor % border shadow color [RGB]
        Selection % selected contents
    end
    
    properties
        SelectionChangedCallback = '' % selection change callback
    end
    
    properties( Access = public, Dependent, AbortSet )
        TabEnables % tab enable states
        TabLocation % tab location [top|bottom]
        TabTitles % tab titles
        TabWidth % tab width
    end
    
    properties( Access = private )
        FontAngle_ = get( 0, 'DefaultUicontrolFontAngle' ) % backing for FontAngle
        FontName_ = get( 0, 'DefaultUicontrolFontName' ) % backing for FontName
        FontSize_ = get( 0, 'DefaultUicontrolFontSize' ) % backing for FontSize
        FontWeight_ = get( 0, 'DefaultUicontrolFontWeight' ) % backing for FontWeight
        FontUnits_ = get( 0, 'DefaultUicontrolFontUnits' ) % backing for FontUnits
        ForegroundColor_ = get( 0, 'DefaultUicontrolForegroundColor' ) % backing for ForegroundColor
        HighlightColor_ = [1 1 1] % backing for HighlightColor
        ShadowColor_ = [0.7 0.7 0.7] % backing for ShadowColor
        Selection_ = 0 % backing for Selection
        Tabs = gobjects( [0 1] ) % tabs
        TabListeners = event.listener.empty( [0 1] ) % tab listeners
        TabLocation_ = 'top' % backing for TabPosition
        TabHeight = -1 % cache of tab height (-1 denotes stale cache)
        TabWidth_ = 50 % backing for TabWidth
        TabDividers = uix.Image.empty( [0 1] ) % tab dividers
        LocationObserver % location observer
        BackgroundColorListener % listener
        SelectionChangedListener % listener
    end
    
    properties( Access = private, Constant )
        FontNames = listfonts() % all available font names
        DividerMask = uix.TabPanel.getDividerMask() % divider image data
        DividerWidth = 8 % divider width
        DividerHeight = 8 % minimum divider height
        Tint = 0.85 % tint factor for unselected tabs
    end
    
    events( NotifyAccess = private )
        SelectionChanged % selection changed
    end
    
    methods
        
        function obj = TabPanel( varargin )
            %uix.TabPanel  Tab panel constructor
            %
            %  p = uix.TabPanel() constructs a tab panel.
            %
            %  p = uix.TabPanel(p1,v1,p2,v2,...) sets parameter p1 to value
            %  v1, etc.
            
            % Call superclass constructor
            obj@uix.Container()
            
            % Create observers and listeners
            locationObserver = uix.LocationObserver( obj );
            backgroundColorListener = event.proplistener( obj, ...
                findprop( obj, 'BackgroundColor' ), 'PostSet', ...
                @obj.onBackgroundColorChange );
            selectionChangedListener = event.listener( obj, ...
                'SelectionChanged', @obj.onSelectionChanged );
            
            % Store properties
            obj.LocationObserver = locationObserver;
            obj.BackgroundColorListener = backgroundColorListener;
            obj.SelectionChangedListener = selectionChangedListener;
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
    methods
        
        function value = get.FontAngle( obj )
            
            value = obj.FontAngle_;
            
        end % get.FontAngle
        
        function set.FontAngle( obj, value )
            
            % Check
            assert( ischar( value ) && any( strcmp( value, {'normal','italic','oblique'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''FontAngle'' must be ''normal'', ''italic'' or ''oblique''.' )
            
            % Set
            obj.FontAngle_ = value;
            
            % Update existing tabs
            tabs = obj.Tabs;
            n = numel( tabs );
            for ii = 1:n
                tab = tabs(ii);
                tab.FontAngle = value;
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            obj.Dirty = true;
            
        end % set.FontAngle
        
        function value = get.FontName( obj )
            
            value = obj.FontName_;
            
        end % get.FontName
        
        function set.FontName( obj, value )
            
            % Check
            assert( ischar( value ) && any( strcmp( value, obj.FontNames ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''FontName'' must be a valid font name.' )
            
            % Set
            obj.FontName_ = value;
            
            % Update existing tabs
            tabs = obj.Tabs;
            n = numel( tabs );
            for ii = 1:n
                tab = tabs(ii);
                tab.FontName = value;
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            obj.Dirty = true;
            
        end % set.FontName
        
        function value = get.FontSize( obj )
            
            value = obj.FontSize_;
            
        end % get.FontSize
        
        function set.FontSize( obj, value )
            
            % Check
            assert( isa( value, 'double' ) && isscalar( value ) && ...
                isreal( value ) && ~isinf( value ) && ...
                ~isnan( value ) && value > 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''FontSize'' must be a positive scalar.' )
            
            % Set
            obj.FontSize_ = value;
            
            % Update existing tabs
            tabs = obj.Tabs;
            n = numel( tabs );
            for ii = 1:n
                tab = tabs(ii);
                tab.FontSize = value;
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            obj.Dirty = true;
            
        end % set.FontSize
        
        function value = get.FontWeight( obj )
            
            value = obj.FontWeight_;
            
        end % get.FontWeight
        
        function set.FontWeight( obj, value )
            
            % Check
            assert( ischar( value ) && any( strcmp( value, {'normal','bold'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''FontWeight'' must be ''normal'' or ''bold''.' )
            
            % Set
            obj.FontWeight_ = value;
            
            % Update existing tabs
            tabs = obj.Tabs;
            n = numel( tabs );
            for ii = 1:n
                tab = tabs(ii);
                tab.FontWeight = value;
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            obj.Dirty = true;
            
        end % set.FontWeight
        
        function value = get.FontUnits( obj )
            
            value = obj.FontUnits_;
            
        end % get.FontUnits
        
        function set.FontUnits( obj, value )
            
            % Check
            assert( ischar( value ) && ...
                any( strcmp( value, {'inches','centimeters','points','pixels'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''FontUnits'' must be ''inches'', ''centimeters'', ''points'' or ''pixels''.' )
            
            % Compute size in new units
            oldUnits = obj.FontUnits_;
            oldSize = obj.FontSize_;
            newUnits = value;
            newSize = oldSize * convert( oldUnits ) / convert( newUnits );
            
            % Set size and units
            obj.FontSize_ = newSize;
            obj.FontUnits_ = newUnits;
            
            % Update existing tabs
            tabs = obj.Tabs;
            n = numel( tabs );
            for ii = 1:n
                tab = tabs(ii);
                tab.FontUnits = newUnits;
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            obj.Dirty = true;
            
            function factor = convert( units )
                %convert  Compute conversion factor to points
                %
                %  f = convert(u) computes the conversion factor from units
                %  u to points.  For example, convert('inches') since 1
                %  inch equals 72 points.
                
                persistent SCREEN_PIXELS_PER_INCH
                if isequal( SCREEN_PIXELS_PER_INCH, [] ) % uninitialized
                    SCREEN_PIXELS_PER_INCH = get( 0, 'ScreenPixelsPerInch' );
                end
                
                switch units
                    case 'inches'
                        factor = 72;
                    case 'centimeters'
                        factor = 72 / 2.54;
                    case 'points'
                        factor = 1;
                    case 'pixels'
                        factor = 72 / SCREEN_PIXELS_PER_INCH;
                end
                
            end % convert
            
        end % set.FontUnits
        
        function value = get.ForegroundColor( obj )
            
            value = obj.ForegroundColor_;
            
        end % get.ForegroundColor
        
        function set.ForegroundColor( obj, value )
            
            % Check
            assert( isnumeric( value ) && isequal( size( value ), [1 3] ) && ...
                all( isreal( value ) ) && all( value >= 0 ) && all( value <= 1 ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''ForegroundColor'' must be an RGB triple.' )
            
            % Set
            obj.ForegroundColor_ = value;
            
            % Update existing tabs
            tabs = obj.Tabs;
            n = numel( tabs );
            for ii = 1:n
                tab = tabs(ii);
                tab.ForegroundColor = value;
            end
            
        end % set.ForegroundColor
        
        function value = get.HighlightColor( obj )
            
            value = obj.HighlightColor_;
            
        end % get.HighlightColor
        
        function set.HighlightColor( obj, value )
            
            % Check
            assert( isnumeric( value ) && isequal( size( value ), [1 3] ) && ...
                all( isreal( value ) ) && all( value >= 0 ) && all( value <= 1 ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''HighlightColor'' must be an RGB triple.' )
            
            % Set
            obj.HighlightColor_ = value;
            
            % Redraw tabs
            obj.redrawTabs()
            
        end % set.HighlightColor
        
        function value = get.Selection( obj )
            
            value = obj.Selection_;
            
        end % get.Selection
        
        function set.SelectionChangedCallback( obj, value )
            
            % Check
            if ischar( value ) % string
                % OK
            elseif isa( value, 'function_handle' ) && ...
                    isequal( size( value ), [1 1] ) % function handle
                % OK
            elseif iscell( value ) && ndims( value ) == 2 && ...
                    size( value, 1 ) == 1 && size( value, 2 ) > 0 && ...
                    isa( value{1}, 'function_handle' ) && ...
                    isequal( size( value{1} ), [1 1] ) %#ok<ISMAT> % cell callback
                % OK
            else
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''SelectionChangedCallback'' must be a valid callback.' )
            end
            
            % Set
            obj.SelectionChangedCallback = value;
            
        end % set.SelectionChangedCallback
        
        function set.Selection( obj, value ) % TODO
            
            % Check
            assert( isa( value, 'double' ), 'uix:InvalidPropertyValue', ...
                'Property ''Selection'' must be of type double.' )
            assert( isequal( size( value ), [1 1] ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''Selection'' must be scalar.' )
            assert( isreal( value ) && rem( value, 1 ) == 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''Selection'' must be an integer.' )
            n = numel( obj.Contents_ );
            if n == 0
                assert( value == 0, 'uix:InvalidPropertyValue', ...
                    'Property ''Selection'' must be 0 for a container with no children.' )
            else
                assert( value >= 1 && value <= n, 'uix:InvalidPropertyValue', ...
                    'Property ''Selection'' must be between 1 and the number of children.' )
                assert( strcmp( obj.Tabs(value).Enable, 'inactive' ), ...
                    'uix:InvalidPropertyValue', 'Cannot select a disabled tab.' )
            end
            
            % Set
            oldSelection = obj.Selection_;
            newSelection = value;
            obj.Selection_ = newSelection;
            
            % Mark as dirty
            obj.Dirty = true;
            
            % Notify selection change
            obj.notify( 'SelectionChanged', ...
                uix.SelectionEvent( oldSelection, newSelection ) )
            
        end % set.Selection
        
        function value = get.ShadowColor( obj )
            
            value = obj.ShadowColor_;
            
        end % get.ShadowColor
        
        function set.ShadowColor( obj, value )
            
            % Check
            assert( isnumeric( value ) && isequal( size( value ), [1 3] ) && ...
                all( isreal( value ) ) && all( value >= 0 ) && all( value <= 1 ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''ShadowColor'' must be an RGB triple.' )
            
            % Set
            obj.ShadowColor_ = value;
            
            % Redraw tabs
            obj.redrawTabs()
            
        end % set.ShadowColor
        
        function value = get.TabEnables( obj )
            
            value = get( obj.Tabs, {'Enable'} );
            value(strcmp( value, 'inactive' )) = {'on'};
            
        end % get.TabEnables
        
        function set.TabEnables( obj, value )
            
            % For those who can't tell a column from a row...
            if isrow( value )
                value = transpose( value );
            end
            
            % Retrieve tabs
            tabs = obj.Tabs;
            tabListeners = obj.TabListeners;
            
            % Check
            assert( iscellstr( value ) && ...
                isequal( size( value ), size( tabs ) ) && ...
                all( strcmp( value, 'on' ) | strcmp( value, 'off' ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabEnables'' should be a cell array of strings ''on'' or ''off'', one per tab.' )
            
            % Set
            tf = strcmp( value, 'on' );
            value(tf) = {'inactive'};
            for ii = 1:numel( tabs )
                tabs(ii).Enable = value{ii};
                tabListeners(ii).Enabled = tf(ii);
            end
            
            % Update selection
            oldSelection = obj.Selection_;
            if oldSelection == 0
                % When no tab was selected, select the last enabled tab
                newSelection = find( tf, 1, 'last' );
                if isempty( newSelection )
                    newSelection = 0;
                end
                obj.Selection_ = newSelection;
                % Mark as dirty
                obj.Dirty = true;
            elseif ~tf(oldSelection)
                % When the tab that was selected is disabled, select the
                % first enabled tab to the right, or failing that, the last
                % enabled tab to the left, or failing that, nothing
                preSelection = find( tf(1:oldSelection-1), 1, 'last' );
                postSelection = oldSelection + ...
                    find( tf(oldSelection+1:end), 1, 'first' );
                if ~isempty( postSelection )
                    newSelection = postSelection;
                elseif ~isempty( preSelection )
                    newSelection = preSelection;
                else
                    newSelection = 0;
                end
                obj.Selection_ = newSelection;
                % Mark as dirty
                obj.Dirty = true;
            else
                % When the tab that was selected is enabled, the previous
                % selection remains valid
                newSelection = oldSelection;
            end
            
            % Notify selection change
            if oldSelection ~= newSelection
                obj.notify( 'SelectionChanged', ...
                    uix.SelectionEvent( oldSelection, newSelection ) )
            end
            
        end % set.TabEnables
        
        function value = get.TabLocation( obj )
            
            value = obj.TabLocation_;
            
        end % get.TabLocation
        
        function set.TabLocation( obj, value )
            
            % Check
            assert( ischar( value ) && ...
                any( strcmp( value, {'top','bottom'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabLocation'' should be ''top'' or ''bottom''.' )
            
            % Set
            obj.TabLocation_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.TabLocation
        
        function value = get.TabTitles( obj )
            
            value = get( obj.Tabs, {'String'} );
            
        end % get.TabTitles
        
        function set.TabTitles( obj, value )
            
            % For those who can't tell a column from a row...
            if isrow( value )
                value = transpose( value );
            end
            
            % Retrieve tabs
            tabs = obj.Tabs;
            
            % Check
            assert( iscellstr( value ) && ...
                isequal( size( value ), size( tabs ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabTitles'' should be a cell array of strings, one per tab.' )
            
            % Set
            n = numel( tabs );
            for ii = 1:n
                tabs(ii).String = value{ii};
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            obj.Dirty = true;
            
        end % set.TabTitles
        
        function value = get.TabWidth( obj )
            
            value = obj.TabWidth_;
            
        end % get.TabWidth
        
        function set.TabWidth( obj, value )
            
            % Check
            assert( isa( value, 'double' ) && isscalar( value ) && ...
                isreal( value ) && ~isinf( value ) && ...
                ~isnan( value ) && value > 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabWidth'' must be a positive scalar.' )
            
            % Set
            obj.TabWidth_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.TabWidth
        
    end % accessors
    
    methods( Access = protected )
        
        function redraw( obj )
            
            % Create or destroy tab dividers
            tabs = obj.Tabs;
            n = numel( tabs ); % number of tabs
            u = numel( obj.TabDividers ); % current number of dividers
            v = sign( n ) * ( n + 1 ); % required number of dividers
            if u < v % create
                for ii = u+1:v
                    divider = uix.Image( 'Internal', true, ...
                        'Parent', obj, 'Units', 'pixels' );
                    obj.TabDividers(ii,:) = divider;
                end
            elseif u > v % destroy
                delete( obj.TabDividers(v+1:u,:) )
                obj.TabDividers(v+1:u,:) = [];
            end
            
            % Compute positions
            location = obj.LocationObserver.Location;
            w = ceil( location(1) + location(3) ) - floor( location(1) ); % width
            h = ceil( location(2) + location(4) ) - floor( location(2) ); % height
            p = obj.Padding_; % padding
            tH = obj.TabHeight; % tab height
            if n > 0 && tH == -1 % cache stale, refresh
                cTabExtents = get( tabs, {'Extent'} );
                tabExtents = vertcat( cTabExtents{:} );
                tH = max( tabExtents(:,4) );
                tH = max( [tH obj.DividerHeight] ); % apply minimum
                obj.TabHeight = tH; % store
            end
            cH = max( [h - 2 * p - tH, 1] ); % contents height
            switch obj.TabLocation_
                case 'top'
                    cY = 1 + p; % contents y
                    tY = cY + cH + p; % tab y
                case 'bottom'
                    tY = 1; % tab y
                    cY = tY + tH + p; % contents y
            end
            cX = 1 + p; % contents x
            cW = max( [w - 2 * p, 1] ); % contents width
            tW = obj.TabWidth_; % tab width
            dW = obj.DividerWidth; % tab divider width
            for ii = 1:n
                tabs(ii).Position = [1 + (ii-1) * tW + ii * dW, tY, tW, tH];
            end
            tabDividers = obj.TabDividers;
            for ii = 1:v
                tabDividers(ii).Position = [1 + (ii-1) * tW + (ii-1) * dW, tY, dW, tH];
            end
            contentsPosition = [cX cY cW cH];
            
            % Redraw tabs
            obj.redrawTabs()
            
            % Redraw contents
            children = obj.Contents_;
            selection = obj.Selection_;
            for ii = 1:numel( children )
                child = children(ii);
                if ii == selection
                    child.Visible = 'on';
                    child.Units = 'pixels';
                    if isa( child, 'matlab.graphics.axis.Axes' )
                        switch child.ActivePositionProperty
                            case 'position'
                                child.Position = contentsPosition;
                            case 'outerposition'
                                child.OuterPosition = contentsPosition;
                            otherwise
                                error( 'uix:InvalidState', ...
                                    'Unknown value ''%s'' for property ''ActivePositionProperty'' of %s.', ...
                                    child.ActivePositionProperty, class( child ) )
                        end
                        child.ContentsVisible = 'on';
                    else
                        child.Position = contentsPosition;
                    end
                else
                    child.Visible = 'off';
                    if isa( child, 'matlab.graphics.axis.Axes' )
                        child.ContentsVisible = 'off';
                    end
                    % As a remedy for g1100294, move off-screen too
                    if isa( child, 'matlab.graphics.axis.Axes' ) ...
                            && strcmp(child.ActivePositionProperty, 'outerposition')
                        child.OuterPosition(1) = -child.OuterPosition(3)-20;
                    else
                        child.Position(1) = -child.Position(3)-20;
                    end
                end
            end
            
        end % redraw
        
        function addChild( obj, child )
            
            % Create new tab
            n = numel( obj.Tabs );
            tab = matlab.ui.control.UIControl( 'Internal', true, ...
                'Parent', obj, 'Style', 'text', 'Enable', 'inactive', ...
                'Units', 'pixels', 'FontUnits', obj.FontUnits_, ...
                'FontSize', obj.FontSize_, 'FontName', obj.FontName_, ...
                'FontAngle', obj.FontAngle_, 'FontWeight', obj.FontWeight_, ...
                'ForegroundColor', obj.ForegroundColor_, ...
                'String', sprintf( 'Page %d', n + 1 ) );
            tabListener = event.listener( tab, 'ButtonDown', @obj.onTabClick );
            obj.Tabs(n+1,:) = tab;
            obj.TabListeners(n+1,:) = tabListener;
            
            % If nothing was selected, select the new content
            oldSelection = obj.Selection_;
            if oldSelection == 0
                newSelection = n + 1;
                obj.Selection_ = newSelection;
            else
                newSelection = oldSelection;
            end
            
            % Mark as dirty
            obj.TabHeight = -1;
            
            % Call superclass method
            addChild@uix.Container( obj, child )
            
            % Notify selection change
            if oldSelection ~= newSelection
                obj.notify( 'SelectionChanged', ...
                    uix.SelectionEvent( oldSelection, newSelection ) )
            end
            
        end % addChild
        
        function removeChild( obj, child )
            
            % Find index of removed child
            contents = obj.Contents_;
            index = find( contents == child );
            
            % Remove tab
            delete( obj.Tabs(index) )
            obj.Tabs(index,:) = [];
            obj.TabListeners(index,:) = [];
            
            % Adjust selection
            oldSelection = obj.Selection_;
            if oldSelection < index
                % When a tab to the right of the selected tab is removed,
                % the previous selection remains valid
            elseif oldSelection > index
                % When a tab to the left of the selected tab is removed,
                % decrement the selection by 1
                newSelection = oldSelection - 1;
                obj.Selection_ = newSelection;
            else
                % When the selected tab is removed, select the first
                % enabled tab to the right, or failing that, the last
                % enabled tab to the left, or failing that, nothing
                tf = strcmp( get( obj.Tabs, {'Enable'} ), 'inactive' );
                preSelection = find( tf(1:oldSelection-1), 1, 'last' );
                postSelection = oldSelection - 1 + ...
                    find( tf(oldSelection:end), 1, 'first' );
                if ~isempty( postSelection )
                    newSelection = postSelection;
                elseif ~isempty( preSelection )
                    newSelection = preSelection;
                else
                    newSelection = 0;
                end
                obj.Selection_ = newSelection;
            end
            
            % Call superclass method
            removeChild@uix.Container( obj, child )
            
            % Notify selection change
            if oldSelection == index
                obj.notify( 'SelectionChanged', ...
                    uix.SelectionEvent( oldSelection, newSelection ) )
            end
            
        end % removeChild
        
        function reorder( obj, indices )
            %reorder  Reorder contents
            %
            %  c.reorder(i) reorders the container contents using indices
            %  i, c.Contents = c.Contents(i).
            
            % Reorder
            obj.Tabs = obj.Tabs(indices,:);
            obj.TabListeners = obj.TabListeners(indices,:);
            selection = obj.Selection_;
            if selection ~= 0
                obj.Selection_ = find( indices == selection );
            end
            
            % Call superclass method
            reorder@uix.Container( obj, indices )
            
        end % reorder
        
        function reparent( obj, oldAncestors, newAncestors )
            %reparent  Reparent container
            %
            %  c.reparent(a,b) reparents the container c from the ancestors
            %  a to the ancestors b.
            
            % Refresh location observer
            locationObserver = uix.LocationObserver( [newAncestors; obj] );
            obj.LocationObserver = locationObserver;
            
            % Call superclass method
            reparent@uix.Container( obj, oldAncestors, newAncestors )
            
        end % reparent
        
    end % template methods
    
    methods( Access = private )
        
        function redrawTabs( obj )
            %redrawTabs  Redraw tabs
            %
            %  p.redrawTabs() redraws the tabs.
            
            % Get relevant properties
            selection = obj.Selection_;
            
            % Repaint tabs
            tabs = obj.Tabs;
            backgroundColor = obj.BackgroundColor;
            for ii = 1:numel( tabs )
                tab = tabs(ii);
                if ii == selection
                    tab.BackgroundColor = backgroundColor;
                else
                    tab.BackgroundColor = obj.Tint * backgroundColor;
                end
            end
            
            % Repaint dividers
            tabDividers = obj.TabDividers;
            n = numel( tabDividers );
            dividerNames = repmat( 'F', [n 2] ); % initialize
            if n > 0
                dividerNames(1,1) = 'E'; % end
                dividerNames(end,2) = 'E'; % end
            end
            if selection ~= 0
                dividerNames(selection,2) = 'T'; % selected
                dividerNames(selection+1,1) = 'T'; % selected
            end
            for ii = 1:n
                tabDivider = tabDividers(ii);
                mask = obj.DividerMask.( dividerNames(ii,:) );
                jMask = zeros( size( mask ), 'int32' ); % initialize
                jMask(mask==0) = uix.Image.rgb2int( obj.ShadowColor );
                jMask(mask==1) = uix.Image.rgb2int( obj.BackgroundColor );
                jMask(mask==2) = uix.Image.rgb2int( obj.Tint * obj.BackgroundColor );
                jMask(mask==3) = uix.Image.rgb2int( obj.HighlightColor );
                jData = repmat( jMask(5,:), [tabDivider.Position(4) 1] );
                jData(1:4,:) = jMask(1:4,:);
                jData(end-3:end,:) = jMask(end-3:end,:);
                switch obj.TabLocation_
                    case 'bottom'
                        jData = flipud( jData );
                end
                tabDivider.JData = jData;
            end
            
        end % redrawTabs
        
    end % helper methods
    
    methods( Access = private )
        
        function onTabClick( obj, source, ~ )
            
            % Update selection
            oldSelection = obj.Selection_;
            newSelection = find( source == obj.Tabs );
            if oldSelection == newSelection, return, end % abort set
            obj.Selection_ = newSelection;
            
            % Mark as dirty
            obj.Dirty = true;
            
            % Notify selection change
            obj.notify( 'SelectionChanged', ...
                uix.SelectionEvent( oldSelection, newSelection ) )
            
        end % onTabClick
        
        function onBackgroundColorChange( obj, ~, ~ )
            
            obj.redrawTabs()
            
        end % onBackgroundColorChange
        
        function onSelectionChanged( obj, source, eventData )
            
            % Call callback
            callback = obj.SelectionChangedCallback;
            if ischar( callback ) && isequal( callback, '' )
                % do nothing
            elseif ischar( callback )
                feval( callback, source, eventData )
            elseif isa( callback, 'function_handle' )
                callback( source, eventData )
            elseif iscell( callback )
                feval( callback{1}, source, eventData, callback{2:end} )
            end
            
        end % onSelectionChanged
        
    end % event handlers
    
    methods( Access = private, Static )
        
        function mask = getDividerMask()
            %getDividerMask  Get divider image data
            %
            %  m = uix.BoxPanel.getDividerMask() returns the image masks
            %  for tab panel dividers.  Mask entries are 0 (shadow), 1
            %  (background), 2 (tint) and 3 (highlight).
            
            mask.EF = sum( uix.loadIcon( 'tab_NoEdge_NotSelected.png' ), 3 );
            mask.ET = sum( uix.loadIcon( 'tab_NoEdge_Selected.png' ), 3 );
            mask.FE = sum( uix.loadIcon( 'tab_NotSelected_NoEdge.png' ), 3 );
            mask.FF = sum( uix.loadIcon( 'tab_NotSelected_NotSelected.png' ), 3 );
            mask.FT = sum( uix.loadIcon( 'tab_NotSelected_Selected.png' ), 3 );
            mask.TE = sum( uix.loadIcon( 'tab_Selected_NoEdge.png' ), 3 );
            mask.TF = sum( uix.loadIcon( 'tab_Selected_NotSelected.png' ), 3 );
            
        end % getDividerMask
        
    end % static helper methods
    
end % classdef