classdef ( Hidden, Sealed ) LocationObserver < handle
    %uix.LocationObserver  Location observer
    %
    %  o = uix.LocationObserver(s) creates a location observer for the
    %  subject s.
    %
    %  o = uix.LocationObserver(a) creates a location observer for the
    %  figure-to-subject ancestry a.
    %
    %  A location observer provides ongoing access to the location on
    %  screen of a subject, and raises an event when the location of the
    %  subject changes.  Location changes are caused by changes to the
    %  Position of the subject or any of its ancestors, or docking or
    %  undocking the parent window.
    %
    %  A location observer assumes a fixed ancestry.  Use an ancestry
    %  observer to monitor changes to ancestry, and create a new location
    %  observer when ancestry changes.
    %
    %  See also: uix.AncestryObserver
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 978 $ $Date: 2014-09-28 14:20:44 -0400 (Sun, 28 Sep 2014) $
    
    properties( SetAccess = private )
        Subject % observer subject
        Location = [NaN NaN NaN NaN] % subject location on screen [pixels]
    end
    
    properties( Access = private )
        Figure % figure
        FigurePanelContainer % figure panel container
        Ancestors % ancestors
        Offsets = zeros( [0 2] ) % offsets [pixels]
        Extent = [NaN NaN] % extent [pixels]
        LocationListeners = event.listener.empty( [0 1] ) % move listeners
        SizeListeners = event.listener.empty( [0 1] ) % resize listeners
        WindowStyleListener = event.proplistener.empty( [0 1] ) % un/dock listener
    end
    
    events( NotifyAccess = private )
        LocationChanged
    end
    
    methods
        
        function obj = LocationObserver( in )
            %uix.LocationObserver  Location observer
            %
            %  o = uix.LocationObserver(s) creates a location observer for
            %  the subject s.
            %
            %  o = uix.LocationObserver(a) creates a location observer
            %  for the figure-to-subject ancestry a.
            %
            %  A location observer assumes a fixed ancestry.  Use an
            %  ancestry observer to monitor changes to ancestry, and create
            %  a new location observer when ancestry changes.
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            warning( 'off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' )
            
            % Handle inputs
            if isscalar( in )
                subject = in;
                assert( isgraphics( subject ) && ...
                    isequal( size( subject ), [1 1] ) && ...
                    ~isequal( subject, ROOT ), ...
                    'uix.InvalidArgument', ...
                    'Subject must be a graphics object.' )
                ancestors = uix.ancestors( subject );
                ancestry = [ancestors; subject];
                parent = ancestry(1).Parent;
                if isequal( parent, ROOT )
                    figure = ancestry(1);
                else
                    figure = parent;
                end
            else
                ancestry = in;
                assert( all( isgraphics( ancestry ) ) && ...
                    ndims( ancestry ) == 2 && iscolumn( ancestry ) && ...
                    ~isempty( ancestry ), 'uix.InvalidArgument', ...
                    'Ancestry must be a vector of graphics objects.' ) %#ok<ISMAT>
                cParents = get( ancestry, {'Parent'} );
                assert( isequal( ancestry(1:end-1,:), ...
                    vertcat( cParents{2:end} ) ), ...
                    'uix:InvalidArgument', 'Inconsistent ancestry.' )
                ancestors = ancestry(1:end-1,:);
                subject = ancestry(end,:);
                if isequal( cParents{1}, ROOT ) % rooted
                    figure = ancestors(1);
                elseif isempty( cParents{1} ) % unrooted
                    figure = cParents{1};
                else % incomplete
                    error( 'uix:InvalidArgument', 'Incomplete ancestry.' )
                end
            end
            
            % Store subject, ancestors, figure
            obj.Subject = subject;
            obj.Ancestors = ancestors;
            obj.Figure = figure;
            
            % Stop early for unrooted subjects
            if isempty( figure ), return, end
            
            % Get figure properties
            jFigurePanelContainer = figure.JavaFrame.getFigurePanelContainer();
            
            % Store figure properties
            obj.FigurePanelContainer = jFigurePanelContainer;
            
            % Force update
            obj.update()
            
            % Create listeners
            locationListeners = event.listener.empty( [0 1] );
            sizeListeners = event.listener.empty( [0 1] );
            cbLocationChanged = @obj.onLocationChanged;
            cbSizeChanged = @obj.onSizeChanged;
            for ii = 1:numel( ancestry )
                ancestor = ancestry(ii);
                locationListeners(ii,:) = event.listener( ancestor, ...
                    'LocationChanged', cbLocationChanged );
                sizeListeners(ii,:) = event.listener( ancestor, ...
                    'SizeChanged', cbSizeChanged );
            end
            windowStyleListener = event.proplistener( figure, ...
                findprop( figure, 'WindowStyle' ), 'PostSet', ...
                @obj.onWindowStyleChange );
            
            % Store listeners
            obj.LocationListeners = locationListeners;
            obj.SizeListeners = sizeListeners;
            obj.WindowStyleListener = windowStyleListener;
            
        end % constructor
        
    end % structors
    
    methods( Access = private )
        
        function update( obj, source )
            %update  Update location observer
            %
            %  o.update() updates the state of the location observer from
            %  scratch.
            %
            %  o.update(a) updates the state of the location observer in
            %  response to an event on the ancestor a.
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            % Retrieve ancestors, parents and figure
            ancestors = obj.Ancestors;
            subject = obj.Subject;
            ancestry = [ancestors; subject];
            parents = [ROOT; ancestry(1:end-1,:)];
            figure = obj.Figure;
            docked = strcmp( figure.WindowStyle, 'docked' );
            
            if nargin == 1 % recompute from scratch
                
                % Compute units, positions and offsets of all ancestors
                units = get( ancestry, {'Units'} );
                cPositions = get( ancestry, {'Position'} );
                positions = vertcat( cPositions{:} );
                n = numel( ancestry );
                offsets = zeros( [n 2] ); % initialize
                for ii = 1:n
                    if ii == 1 && docked
                        pixel = getFigurePixelPosition( ...
                            obj.FigurePanelContainer );
                    elseif isa( ancestry(ii), 'matlab.ui.container.Panel' )
                        pixel = hgconvertunits( figure, positions(ii,:), ...
                            units{ii}, 'pixels', parents(ii) ) + ...
                            [getPanelMargin( ancestry(ii) ) 0 0];
                    else
                        pixel = hgconvertunits( figure, positions(ii,:), ...
                            units{ii}, 'pixels', parents(ii) );
                    end
                    offsets(ii,:) = pixel(1:2) - 1;
                end
                extent = pixel(3:4); % ii == n
                
            else % specified modified ancestor
                
                % Compute units, position and offset of modified ancestor
                tf = ancestry == source;
                ancestor = ancestry(tf);
                parent = parents(tf);
                if tf(1) && docked % docked figure
                    pixel = getFigurePixelPosition( ...
                        obj.FigurePanelContainer );
                elseif isa( ancestor, 'matlab.ui.container.Panel' )
                    pixel = hgconvertunits( figure, ancestor.Position, ...
                        ancestor.Units, 'pixels', parent ) + ...
                        [getPanelMargin( ancestor ) 0 0];
                else % undocked figure or non-figure
                    pixel = hgconvertunits( figure, ancestor.Position, ...
                        ancestor.Units, 'pixels', parent );
                end
                offset = pixel(1:2) - 1;
                offsets = obj.Offsets;
                offsets(tf,:) = offset;
                if tf(end) % subject
                    extent = pixel(3:4);
                else
                    extent = obj.Extent;
                end
                
            end
            
            % Compute location
            location = [sum( offsets, 1 ) extent];
            
            % Store properties
            obj.Offsets = offsets;
            obj.Extent = extent;
            obj.Location = location;
            
            % Raise event
            notify( obj, 'LocationChanged' )
            
            function p = getFigurePixelPosition( jFigurePanelContainer )
                %getFigurePixelPosition  Get figure position in pixels
                %
                %  p = getFigurePixelPosition(c) returns the position in
                %  pixels p of the figure panel container c.
                
                screenSize = ROOT.ScreenSize;
                r = 0; % number of failed calls to getLocationOnScreen
                while true
                    try
                        jLocation = jFigurePanelContainer.getLocationOnScreen();
                        break
                    catch e
                        pause( 0.01 ) % pause briefly
                        r = r + 1; % increment counter
                        if r > 10 % maximum number of retries exceeded
                            e.rethrow()
                        end
                    end
                end
                x = jLocation.getX();
                y = jLocation.getY();
                w = jFigurePanelContainer.getWidth();
                h = jFigurePanelContainer.getHeight();
                p = [x+1, screenSize(4)-y-h+1, w, h];
                
            end % getFigurePixelPosition
            
            function m = getPanelMargin( panel )
                %getPanelMargin  Get panel margin in pixels
                %
                %  m = getPanelMargin(p) returns the margin in pixels m of
                %  the panel p.  The margin is the width and height of the
                %  decoration in the lower left corner.
                
                outerBounds = hgconvertunits( figure, ...
                    panel.Position, panel.Units, 'pixels', panel.Parent );
                innerBounds = hgconvertunits( figure, ...
                    [0 0 1 1], 'normalized', 'pixels', panel );
                titlePosition = panel.TitlePosition;
                borderType = panel.BorderType;
                borderWidth = panel.BorderWidth;
                switch borderType
                    case 'none'
                        borderFactor = 0;
                    case 'line'
                        borderFactor = 1;
                    otherwise
                        borderFactor = 2;
                end
                switch titlePosition
                    case {'lefttop','centertop','righttop'}
                        m = borderWidth * borderFactor * [1 1];
                    otherwise
                        m = [0 outerBounds(4) - innerBounds(4)] + ...
                            borderWidth * borderFactor * [1 -1];
                end
                
            end % getPanelMargin
            
        end % update
        
    end % operations
    
    methods( Access = private )
        
        function onLocationChanged( obj, source, ~ )
            
            % Update
            obj.update( source )
            
        end % onLocationChanged
        
        function onSizeChanged( obj, source, ~ )
            
            % Update
            obj.update( source )
            
        end % onSizeChanged
        
        function onWindowStyleChange( obj, ~, eventData )
            
            % Update
            obj.update( eventData.AffectedObject )
            
        end % onWindowStyleChange
        
    end % event handlers
    
end % classdef