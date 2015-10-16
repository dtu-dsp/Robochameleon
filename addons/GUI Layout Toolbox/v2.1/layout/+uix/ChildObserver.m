classdef ( Hidden, Sealed ) ChildObserver < handle
    %uix.ChildObserver  Child observer
    %
    %  co = uix.ChildObserver(o) creates a child observer for the graphics
    %  object o.  A child observer raises events when objects are added to
    %  and removed from the property Children of o.
    %
    %  See also: uix.AncestryObserver, uix.Node
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 978 $ $Date: 2014-09-28 14:20:44 -0400 (Sun, 28 Sep 2014) $
    
    properties( Access = private )
        Root % root node
    end
    
    events( NotifyAccess = private )
        ChildAdded % child added
        ChildRemoved % child removed
    end
    
    methods
        
        function obj = ChildObserver( oRoot )
            %uix.ChildObserver  Child observer
            %
            %  co = uix.ChildObserver(o) creates a child observer for the
            %  graphics object o.  A child observer raises events when
            %  objects are added to and removed from the property Children
            %  of o.
            
            % Check
            assert( isgraphics( oRoot ) && ...
                isequal( size( oRoot ), [1 1] ), 'uix.InvalidArgument', ...
                'Object must be a graphics object.' )
            
            % Create root node
            nRoot = uix.Node( oRoot );
            childAddedListener = event.listener( oRoot, ...
                'ObjectChildAdded', ...
                @(~,e)obj.addChild(nRoot,e.Child) );
            childAddedListener.Recursive = true;
            nRoot.addprop( 'ChildAddedListener' );
            nRoot.ChildAddedListener = childAddedListener;
            childRemovedListener = event.listener( oRoot, ...
                'ObjectChildRemoved', ...
                @(~,e)obj.removeChild(nRoot,e.Child) );
            childRemovedListener.Recursive = true;
            nRoot.addprop( 'ChildRemovedListener' );
            nRoot.ChildRemovedListener = childRemovedListener;
            
            % Add children
            oChildren = hgGetTrueChildren( oRoot );
            for ii = 1:numel( oChildren )
                obj.addChild( nRoot, oChildren(ii) )
            end
            
            % Store properties
            obj.Root = nRoot;
            
        end % constructor
        
    end % structors
    
    methods( Access = private )
        
        function addChild( obj, nParent, oChild )
            %addChild  Add child object to parent node
            %
            %  co.addChild(np,oc) adds the child object oc to the parent
            %  node np, either as part of construction of the child
            %  observer co, or in response to an ObjectChildAdded event on
            %  an object of interest to co.  This may lead to ChildAdded
            %  events being raised on co.
            
            % Create child node
            nChild = uix.Node( oChild );
            nParent.addChild( nChild )
            if isgraphics( oChild )
                % Add Internal PreSet property listener
                internalPreSetListener = event.proplistener( oChild, ...
                    findprop( oChild, 'Internal' ), 'PreSet', ...
                    @(~,~)obj.preSetInternal(nChild) );
                nChild.addprop( 'InternalPreSetListener' );
                nChild.InternalPreSetListener = internalPreSetListener;
                % Add Internal PostSet property listener
                internalPostSetListener = event.proplistener( oChild, ...
                    findprop( oChild, 'Internal' ), 'PostSet', ...
                    @(~,~)obj.postSetInternal(nChild) );
                nChild.addprop( 'InternalPostSetListener' );
                nChild.InternalPostSetListener = internalPostSetListener;
            else
                % Add ObjectChildAdded listener
                childAddedListener = event.listener( oChild, ...
                    'ObjectChildAdded', ...
                    @(~,e)obj.addChild(nChild,e.Child) );
                nChild.addprop( 'ChildAddedListener' );
                nChild.ChildAddedListener = childAddedListener;
                % Add ObjectChildRemoved listener
                childRemovedListener = event.listener( oChild, ...
                    'ObjectChildRemoved', ...
                    @(~,e)obj.removeChild(nChild,e.Child) );
                nChild.addprop( 'ChildRemovedListener' );
                nChild.ChildRemovedListener = childRemovedListener;
            end
            
            % Raise ChildAdded event
            if isgraphics( oChild ) && oChild.Internal == false
                if verLessThan( 'MATLAB', '8.5' ) && ...
                        isa( oChild, 'matlab.ui.control.UIControl' ) % TODO
                    %  A workaround is required in R2014b for G1129721,
                    %  where setting the property 'Visible' of a uicontrol
                    %  to 'on' in response to an ObjectChildAdded event
                    %  causes a crash.  Instead, the property set must be
                    %  postponed until the PostSet event of the uicontrol
                    %  property 'Parent', which follows the
                    %  ObjectChildAdded event.  Thus it is necessary to
                    %  ensure that the ChildAdded event on the
                    %  ChildObserver does not fire until it is safe to set
                    %  the property 'Visible' of the child.
                    parentPostSetListener = event.proplistener( oChild, ...
                        findprop( oChild, 'Parent' ), 'PostSet', ...
                        @(~,~)obj.postSetParent(nChild) );
                    nChild.addprop( 'ParentPostSetListener' );
                    nChild.ParentPostSetListener = parentPostSetListener;
                else
                    notify( obj, 'ChildAdded', uix.ChildEvent( oChild ) )
                end
            end
            
            % Add grandchildren
            if ~isgraphics( oChild )
                oGrandchildren = hgGetTrueChildren( oChild );
                for ii = 1:numel( oGrandchildren )
                    obj.addChild( nChild, oGrandchildren(ii) )
                end
            end
            
        end % addChild
        
        function removeChild( obj, nParent, oChild )
            %removeChild  Remove child object from parent node
            %
            %  co.removeChild(np,oc) removes the child object oc from the
            %  parent node np, in response to an ObjectChildRemoved event
            %  on an object of interest to co.  This may lead to
            %  ChildRemoved events being raised on co.
            
            % Get child node
            nChildren = nParent.Children;
            tf = oChild == [nChildren.Object];
            nChild = nChildren(tf);
            
            % Raise ChildRemoved event(s)
            notifyChildRemoved( nChild )
            
            % Delete child node
            delete( nChild )
            
            function notifyChildRemoved( nc )
                
                % Process child nodes
                ngc = nc.Children;
                for ii = 1:numel( ngc )
                    notifyChildRemoved( ngc(ii) )
                end
                
                % Process this node
                oc = nc.Object;
                if isgraphics( oc ) && oc.Internal == false
                    notify( obj, 'ChildRemoved', uix.ChildEvent( oc ) )
                end
                
            end % notifyChildRemoved
            
        end % removeChild
        
        function preSetInternal( ~, nChild )
            %preSetInternal  Perform property PreSet tasks
            %
            %  co.preSetInternal(n) caches the previous value of the
            %  property Internal of the object referenced by the node n, to
            %  enable PostSet tasks to identify whether the value changed.
            %  This is necessary since Internal AbortSet is false.
            
            oldInternal = nChild.Object.Internal;
            nChild.addprop( 'OldInternal' );
            nChild.OldInternal = oldInternal;
            
        end % preSetInternal
        
        function postSetInternal( obj, nChild )
            %postSetInternal  Perform property PostSet tasks
            %
            %  co.postSetInternal(n) raises a ChildAdded or ChildRemoved
            %  event on the child observer co in response to a change of
            %  the value of the property Internal of the object referenced
            %  by the node n.
            
            % Retrieve old and new values
            oChild = nChild.Object;
            newInternal = oChild.Internal;
            oldInternal = nChild.OldInternal;
            
            % Clean up node
            delete( findprop( nChild, 'OldInternal' ) )
            
            % Raise event
            switch newInternal
                case oldInternal % no change
                    % no event
                case true % false to true
                    notify( obj, 'ChildRemoved', uix.ChildEvent( oChild ) )
                case false % true to false
                    notify( obj, 'ChildAdded', uix.ChildEvent( oChild ) )
            end
            
        end % postSetInternal
        
        function postSetParent( obj, nChild )
            
            % Clean up node
            delete( findprop( nChild, 'ParentPostSetListener' ) )
            
            % Raise event
            oChild = nChild.Object;
            notify( obj, 'ChildAdded', uix.ChildEvent( oChild ) )
            
        end % postSetParent
        
    end % event handlers
    
end % classdef