classdef VButtonBox < uix.ButtonBox
    %uix.VButtonBox  Vertical button box
    %
    %  b = uix.VButtonBox(p1,v1,p2,v2,...) constructs a vertical button box
    %  and sets parameter p1 to value v1, etc.
    %
    %  A vertical button box lays out equally sized buttons from top to
    %  bottom.
    %
    %  See also: uix.HButtonBox
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 986 $ $Date: 2014-09-28 15:01:25 -0400 (Sun, 28 Sep 2014) $
    
    methods
        
        function obj = VButtonBox( varargin )
            %uix.VButtonBox  Vertical button box constructor
            %
            %  b = uix.VButtonBox() constructs a vertical button box.
            %
            %  b = uix.VButtonBox(p1,v1,p2,v2,...) sets parameter p1 to
            %  value v1, etc.
            
            % Call superclass constructor
            obj@uix.ButtonBox()
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
    methods( Access = protected )
        
        function redraw( obj )
            
            % Compute positions
            bounds = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            buttonSize = obj.ButtonSize_;
            padding = obj.Padding_;
            spacing = obj.Spacing_;
            r = numel( obj.Contents_ );
            if 2 * padding + buttonSize(1) > bounds(3)
                xSizes = repmat( uix.calcPixelSizes( bounds(3), -1, 1, ...
                    padding, spacing ), [r 1] ); % shrink to fit
            else
                xSizes = repmat( buttonSize(1), [r 1] );
            end
            switch obj.HorizontalAlignment
                case 'left'
                    xPositions = [repmat( padding, [r 1] ) + 1, xSizes];
                case 'center'
                    xPositions = [(bounds(3) - xSizes) / 2 + 1, xSizes];
                case 'right'
                    xPositions = [bounds(3) - xSizes - padding + 1, xSizes];
            end
            if 2 * padding + (r-1) * spacing + r * buttonSize(2) > bounds(4)
                ySizes = uix.calcPixelSizes( bounds(4), -ones( [r 1] ), ...
                    ones( [r 1] ), padding, spacing ); % shrink to fit
            else
                ySizes = repmat( buttonSize(2), [r 1] );
            end
            switch obj.VerticalAlignment
                case 'top'
                    yPositions = [bounds(4) - padding - cumsum( ySizes ) - ...
                        spacing * transpose( 0:r-1 ) + 1, ySizes];
                case 'middle'
                    yPositions = [bounds(4) / 2  + sum( ySizes ) / 2  + ...
                        spacing * (r-1) / 2 - cumsum( ySizes ) - ...
                        spacing * transpose( 0:r-1 ) + 1, ySizes];
                case 'bottom'
                    yPositions = [sum( ySizes ) + spacing * (r-1) - ...
                        cumsum( ySizes ) - spacing * transpose( 0:r-1 ) + ...
                        padding + 1, ySizes];
            end
            positions = [xPositions(:,1), yPositions(:,1), ...
                xPositions(:,2), yPositions(:,2)];
            
            % Set positions
            children = obj.Contents_;
            for ii = 1:numel( children )
                child = children(ii);
                child.Units = 'pixels';
                if isa( child, 'matlab.graphics.axis.Axes' )
                    switch child.ActivePositionProperty
                        case 'position'
                            child.Position = positions(ii,:);
                        case 'outerposition'
                            child.OuterPosition = positions(ii,:);
                        otherwise
                            error( 'uix:InvalidState', ...
                                'Unknown value ''%s'' for property ''ActivePositionProperty'' of %s.', ...
                                child.ActivePositionProperty, class( child ) )
                    end
                else
                    child.Position = positions(ii,:);
                end
            end
            
        end % redraw
        
    end % template methods
    
end % classdef