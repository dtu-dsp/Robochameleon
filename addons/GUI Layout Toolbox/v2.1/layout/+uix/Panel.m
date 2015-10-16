classdef Panel < matlab.ui.container.Panel & uix.mixin.Container
    %uix.Panel  Standard panel
    %
    %  b = uix.Panel(p1,v1,p2,v2,...) constructs a standard panel and sets
    %  parameter p1 to value v1, etc.
    %
    %  A card panel is a standard panel (uipanel) that shows one its
    %  contents and hides the others.
    %
    %  See also: uix.CardPanel, uix.BoxPanel, uipanel
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 992 $ $Date: 2014-09-29 04:20:51 -0400 (Mon, 29 Sep 2014) $
    
    properties( Access = public, Dependent, AbortSet )
        Selection % selected contents
    end
    
    properties( Access = protected )
        Selection_ = 0 % backing for Selection
    end
    
    methods
        
        function obj = Panel( varargin )
            %uix.Panel  Standard panel constructor
            %
            %  p = uix.Panel() constructs a standard panel.
            %
            %  p = uix.Panel(p1,v1,p2,v2,...) sets parameter p1 to value
            %  v1, etc.
            
            % Call superclass constructor
            obj@matlab.ui.container.Panel()
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
    methods
        
        function value = get.Selection( obj )
            
            value = obj.Selection_;
            
        end % get.Selection
        
        function set.Selection( obj, value )
            
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
            end
            
            % Set
            obj.Selection_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.Selection
        
    end % accessors
    
    methods( Access = protected )
        
        function redraw( obj )
            
            % Compute positions
            bounds = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            padding = obj.Padding_;
            xSizes = uix.calcPixelSizes( bounds(3), -1, 1, padding, 0 );
            ySizes = uix.calcPixelSizes( bounds(4), -1, 1, padding, 0 );
            position = [padding+1 padding+1 xSizes ySizes];
            
            % Set positions and visibility
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
                                child.Position = position;
                            case 'outerposition'
                                child.OuterPosition = position;
                            otherwise
                                error( 'uix:InvalidState', ...
                                    'Unknown value ''%s'' for property ''ActivePositionProperty'' of %s.', ...
                                    child.ActivePositionProperty, class( child ) )
                        end
                        child.ContentsVisible = 'on';
                    else
                        child.Position = position;
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
            
            % Select new content
            obj.Selection_ = numel( obj.Contents_ ) + 1;
            
            % Call superclass method
            addChild@uix.mixin.Container( obj, child )
            
        end % addChild
        
        function removeChild( obj, child )
            
            % Adjust selection if required
            contents = obj.Contents_;
            n = numel( contents );
            index = find( contents == child );
            selection = obj.Selection_;
            if index == 1 && selection == 1 && n > 1
                % retain selection
            elseif index <= selection
                obj.Selection_ = selection - 1;
            else
                % retain selection
            end
            
            % Call superclass method
            removeChild@uix.mixin.Container( obj, child )
            
        end % removeChild
        
        function reorder( obj, indices )
            %reorder  Reorder contents
            %
            %  c.reorder(i) reorders the container contents using indices
            %  i, c.Contents = c.Contents(i).
            
            % Reorder
            selection = obj.Selection_;
            if selection ~= 0
                obj.Selection_ = find( indices == selection );
            end
            
            % Call superclass method
            reorder@uix.mixin.Container( obj, indices )
            
        end % reorder
        
    end % template methods
    
end % classdef