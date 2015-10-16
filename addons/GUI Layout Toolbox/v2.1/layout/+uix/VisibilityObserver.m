classdef ( Hidden, Sealed ) VisibilityObserver < handle
    %uix.VisibilityObserver  Visibility observer
    %
    %  o = uix.VisibilityObserver(s) creates a visibility observer for the
    %  subject s.
    %
    %  o = uix.VisibilityObserver(a) creates a visibility observer for the
    %  figure-to-subject ancestry a.
    %
    %  A visibility observer raises an event when the subject visibility
    %  changes.  To be visible, the subject must be rooted and the Visible
    %  property of the subject and all of its ancestors must be 'on'.
    %
    %  A visibility observer assumes a fixed ancestry.  Use an ancestry
    %  observer to monitor changes to ancestry, and create a new visibility
    %  observer when ancestry changes.
    %
    %  See also: uix.AncestryObserver
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 978 $ $Date: 2014-09-28 14:20:44 -0400 (Sun, 28 Sep 2014) $
    
    properties( SetAccess = private )
        Subject % subject
        Visible = false % state
    end
    
    properties( Access = private )
        Ancestors % ancestors, from figure to subject
        VisibleListeners = event.listener.empty( [0 1] ) % listeners
    end
    
    events( NotifyAccess = private )
        VisibilityChange % visibility change
    end
    
    methods
        
        function obj = VisibilityObserver( in )
            %uix.VisibilityObserver  Visibility observer
            %
            %  o = uix.VisibilityObserver(s) creates a visibility observer
            %  for the subject s.
            %
            %  o = uix.VisibilityObserver(a) creates a visibility observer
            %  for the figure-to-subject ancestry a.
            %
            %  A visibility observer assumes a fixed ancestry.  Use an
            %  ancestry observer to monitor changes to ancestry, and create
            %  a new visibility observer when ancestry changes.
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
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
                assert( isequal( cParents{1}, ROOT ) || isempty( cParents{1} ), ...
                    'uix:InvalidArgument', 'Incomplete ancestry.' )
                subject = ancestry(end,:);
                ancestors = ancestry(1:end-1,:);
            end
            
            % Store subject, ancestors
            obj.Subject = subject;
            obj.Ancestors = ancestors;
            
            % Stop early for unrooted subjects
            if ~isequal( ancestry(1).Parent, ROOT ), return, end
            
            % Force update
            obj.update()
            
            % Create listeners
            visibleListeners = event.listener.empty( [0 1] );
            cbVisibleChange = @obj.onVisibleChange;
            for ii = 1:numel( ancestry )
                ancestor = ancestry(ii);
                visibleListeners(ii,:) = event.proplistener( ancestor, ...
                    findprop( ancestor, 'Visible' ), 'PostSet', ...
                    cbVisibleChange );
            end
            
            % Store listeners
            obj.VisibleListeners = visibleListeners;
            
        end % constructor
        
    end % structors
    
    methods( Access = private )
        
        function update( obj )
            %update  Update visibility observer
            %
            %  o.update() updates the state of the visibility observer.
            
            % Identify new value
            ancestry = [obj.Ancestors; obj.Subject];
            visibles = cell( size( ancestry ) ); % preallocate
            for ii = 1:numel( ancestry )
                ancestor = ancestry(ii);
                if isprop( ancestor, 'Visible' )
                    visibles{ii} = ancestor.Visible;
                else
                    visibles{ii} = 'on';
                end
            end
            newVisible = all( strcmp( visibles, 'on' ) );
            
            % Store new value
            obj.Visible = newVisible;
            
        end % update
        
    end % operations
    
    methods( Access = private )
        
        function onVisibleChange( obj, ~, ~ )
            %onVisibleChange  Event handler
            
            % Capture old state
            oldVisible = obj.Visible;
            
            % Update
            obj.update()
            
            % Capture new state
            newVisible = obj.Visible;
            
            % Raise event
            if oldVisible ~= newVisible
                notify( obj, 'VisibilityChange' )
            end
            
        end % onVisibleChange
        
    end % event handlers
    
end % classdef