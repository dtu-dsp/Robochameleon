classdef ( Hidden, Sealed ) AncestryObserver < handle
    %uix.AncestryObserver  Ancestry observer
    %
    %  o = uix.AncestryObserver(s) creates an ancestry observer for the
    %  subject s.
    %
    %  o = uix.LocationObserver(a) creates an ancestry observer for the
    %  figure-to-subject ancestry a.
    %
    %  An ancestry observer provides ongoing access to the ancestry of a
    %  subject, and raises events before and after a parent of the subject
    %  or one of its ancestors changes.
    %
    %  See also: uix.ChildObserver

    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 998 $ $Date: 2014-10-01 14:48:20 -0400 (Wed, 01 Oct 2014) $
    
    properties( GetAccess = public, SetAccess = private )
        Subject % subject
        Ancestors % ancestors, from figure to subject
    end
    
    properties( Access = private )
        ParentListeners % listeners
    end
    
    events( NotifyAccess = private )
        AncestryPreChange % ancestry will change
        AncestryPostChange % ancestry did change
    end
    
    methods
        
        function obj = AncestryObserver( subject )
            %uix.AncestryObserver  Ancestry observer
            %
            %  o = uix.AncestryObserver(s) creates an ancestry observer for
            %  the subject s.
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            % Check
            assert( isgraphics( subject ) && ...
                isequal( size( subject ), [1 1] ) && ...
                ~isequal( subject, ROOT ), ...
                'uix.InvalidArgument', ...
                'Subject must be a graphics object.' )
            
            % Store properties
            obj.Subject = subject;
            
            % Force update
            obj.update()
            
        end % constructor
        
    end
    
    methods( Access = private )
        
        function update( obj )
            %update  Update ancestry observer
            %
            %  o.update() updates the state of the ancestry observer by
            %  identifying the ancestors and creating listeners to the
            %  subject and ancestors.
            
            persistent ROOT
            if isequal( ROOT, [] ), ROOT = groot(); end
            
            % Identify new ancestors
            subject = obj.Subject;
            newAncestors = uix.ancestors( subject );
            newAncestry = [newAncestors; subject];
            
            % Create listeners
            preListeners = event.listener.empty( [0 1] ); % initialize
            postListeners = event.listener.empty( [0 1] ); % initialize
            cbPreChange = @obj.onPreChange;
            cbPostChange = @obj.onPostChange;
            for ii = 1:numel( newAncestry )
                ancestor = newAncestry(ii);
                preListeners(ii,:) = event.proplistener( ancestor, ...
                    findprop( ancestor, 'Parent' ), 'PreSet', cbPreChange );
                postListeners(ii,:) = event.proplistener( ancestor, ...
                    findprop( ancestor, 'Parent' ), 'PostSet', cbPostChange );
            end
            
            % Store properties
            obj.Ancestors = newAncestors;
            obj.ParentListeners = [preListeners postListeners];
            
        end % update
        
    end % methods
    
    methods( Access = private )
        
        function onPreChange( obj, ~, ~ )
            %onPreChange  Event handler
            
            % Raise event
            notify( obj, 'AncestryPreChange' )
            
        end % onPreChange
        
        function onPostChange( obj, ~, ~ )
            %onPostChange  Event handler
            
            % Update
            obj.update()
            
            % Raise event
            notify( obj, 'AncestryPostChange' )
            
        end % onPostChange
        
    end % event handlers
    
end % classdef