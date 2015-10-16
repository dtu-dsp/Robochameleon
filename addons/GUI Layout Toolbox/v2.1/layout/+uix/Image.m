classdef Image < hgsetget
    %uix.Image  Image
    %
    %  im = uix.Image(p1,v1,p2,v2,...) constructs an image and sets
    %  parameter p1 to value v1, etc.
    %
    %  This class wraps a JLabel to provide a relatively lightweight way to
    %  present arbitrary CData and to align it both horizontally and
    %  vertically (unlike a uicontrol) and without the overhead of creating
    %  axes.
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 986 $ $Date: 2014-09-28 15:01:25 -0400 (Sun, 28 Sep 2014) $
    
    properties( Access = private )
        Label % javax.swing.JLabel
        Container % container peer
    end
    
    properties( Dependent )
        Parent % parent
        Units % units [inches|centimeters|characters|normalized|points|pixels]
        Position % position
        Visible % visible [on|off]
        HorizontalAlignment % horizontal alignment [left|center|right]
        VerticalAlignment % vertical alignment [top|middle|bottom]
        CData % RGB image data
    end
    
    properties( Dependent, Hidden )
        Internal % internal
        JData % Java integer image data
    end
    
    methods
        
        function obj = Image( varargin )
            %uix.Image  Image constructor
            %
            %  im = uix.Image() constructs an image.
            %
            %  im = uix.Image(p1,v1,p2,v2,...) sets parameter p1 to value
            %  v1, etc.
            
            % Create label and container
            label = javaObjectEDT( 'javax.swing.JLabel' );
            container = hgjavacomponent( 'Parent', [], ...
                'JavaPeer', label, 'DeleteFcn', @obj.onDelete );
            
            % Store properties
            obj.Label = label;
            obj.Container = container;
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
        function delete( obj )
            
            container = obj.Container;
            if isgraphics( container ) && strcmp( container.BeingDeleted, 'off' )
                delete( container )
            end
            
        end % destructor
        
    end % structors
    
    methods
        
        function value = get.Parent( obj )
            
            value = obj.Container.Parent;
            
        end % get.Parent
        
        function set.Parent( obj, value )
            
            obj.Container.Parent = value;
            
        end % set.Parent
        
        function value = get.Units( obj )
            
            value = obj.Container.Units;
            
        end % get.Units
        
        function set.Units( obj, value )
            
            obj.Container.Units = value;
            
        end % set.Units
        
        function value = get.Position( obj )
            
            value = obj.Container.Position;
            
        end % get.Position
        
        function set.Position( obj, value )
            
            obj.Container.Position = value;
            
        end % set.Position
        
        function value = get.Visible( obj )
            
            value = obj.Container.Visible;
            
        end % get.Visible
        
        function set.Visible( obj, value )
            
            obj.Container.Visible = value;
            
        end % set.Visible
        
        function value = get.HorizontalAlignment( obj )
            
            switch obj.Label.getHorizontalAlignment()
                case javax.swing.SwingConstants.LEADING % JLabel default
                    value = 'left';
                case javax.swing.SwingConstants.LEFT
                    value = 'left';
                case javax.swing.SwingConstants.CENTER
                    value = 'center';
                case javax.swing.SwingConstants.RIGHT
                    value = 'right';
            end
            
        end % get.HorizontalAlignment
        
        function set.HorizontalAlignment( obj, value )
            
            % Check
            assert( ischar( value ) && any( strcmp( value, {'left','center','right'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''HorizontalAlignment'' must be ''left'', ''center'' or ''right''.' )
            
            % Set
            switch value
                case 'left'
                    alignment = javax.swing.SwingConstants.LEFT;
                case 'center'
                    alignment = javax.swing.SwingConstants.CENTER;
                case 'right'
                    alignment = javax.swing.SwingConstants.RIGHT;
            end
            obj.Label.setHorizontalAlignment( alignment )
            
        end % set.HorizontalAlignment
        
        function value = get.VerticalAlignment( obj )
            
            switch obj.Label.getVerticalAlignment()
                case javax.swing.SwingConstants.TOP
                    value = 'top';
                case javax.swing.SwingConstants.CENTER
                    value = 'middle';
                case javax.swing.SwingConstants.BOTTOM
                    value = 'bottom';
            end
            
        end % get.VerticalAlignment
        
        function set.VerticalAlignment( obj, value )
            
            % Check
            assert( ischar( value ) && any( strcmp( value, {'left','center','right'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''VerticalAlignment'' must be ''top'', ''middle'' or ''bottom''.' )
            
            % Set
            switch value
                case 'top'
                    alignment = javax.swing.SwingConstants.TOP;
                case 'middle'
                    alignment = javax.swing.SwingConstants.CENTER;
                case 'bottom'
                    alignment = javax.swing.SwingConstants.BOTTOM;
            end
            obj.Label.setVerticalAlignment( alignment )
            
        end % set.VerticalAlignment
        
        function value = get.CData( obj )
            
            mI = obj.JData;
            sz = size( mI );
            vI = reshape( mI, [sz(1)*sz(2) 1] );
            vC = uix.Image.int2rgb( vI );
            value = reshape( vC, [size( mI ) 3] );
            
        end % get.CData
        
        function set.CData( obj, value )
            
            % Check
            assert( isnumeric( value ) && ndims( value ) == 3 && ...
                size( value, 3 ) == 3 && all( value(:) >= 0 ) && ...
                all( value(:) <= 1 ), 'uix.InvalidPropertyValue', ...
                'Property ''CData'' must be an m-by-n-by-3 matrix of values between 0 and 1.' )
            
            % Set
            if isempty( value )
                obj.Label.setIcon( [] )
            else
                sz = size( value );
                vC = transpose( reshape( permute( value, [3 2 1] ), ...
                    [sz(3) sz(1)*sz(2)] ) );
                vI = uix.Image.rgb2int( vC );
                bufferedImage = java.awt.image.BufferedImage( sz(2), ...
                    sz(1), java.awt.image.BufferedImage.TYPE_INT_ARGB );
                bufferedImage.setRGB( 0, 0, sz(2), sz(1), vI, 0, sz(2) )
                imageIcon = javax.swing.ImageIcon( bufferedImage );
                obj.Label.setIcon( imageIcon )
            end
            
        end % set.CData
        
        function value = get.JData( obj )
            
            imageIcon = obj.Label.getIcon();
            if isequal( imageIcon, [] )
                value = zeros( [0 0], 'int32' );
            else
                bufferedImage = imageIcon.getImage();
                width = bufferedImage.getWidth();
                height = bufferedImage.getHeight();
                vI = bufferedImage.getRGB( 0, 0, width, height, ...
                    zeros( [width*height 1], 'int32' ), 0, width );
                value = transpose( reshape( vI, [width height] ) );
            end
            
        end % get.JData
        
        function set.JData( obj, value )
            
            % Check
            assert( isa( value, 'int32' ) && ndims( value ) == 2 && ...
                all( value(:) < 0 ), 'uix.InvalidPropertyValue', ...
                'Property ''JData'' must be a matrix of type int32.' ) %#ok<ISMAT>
            
            % Set
            if isempty( value )
                obj.Label.setIcon( [] )
            else
                sz = size( value );
                vI = reshape( transpose( value ), [sz(1)*sz(2) 1] );
                bufferedImage = java.awt.image.BufferedImage( sz(2), ...
                    sz(1), java.awt.image.BufferedImage.TYPE_INT_ARGB );
                bufferedImage.setRGB( 0, 0, sz(2), sz(1), vI, 0, sz(2) )
                imageIcon = javax.swing.ImageIcon( bufferedImage );
                obj.Label.setIcon( imageIcon )
            end
            
        end % set.JData
        
        function value = get.Internal( obj )
            
            value = obj.Container.Internal;
            
        end % get.Internal
        
        function set.Internal( obj, value )
            
            obj.Container.Internal = value;
            
        end % set.Internal
        
    end % accessors
    
    methods( Access = private )
        
        function onDelete( obj, ~, ~ )
            
            obj.delete()
            
        end % onDelete
        
    end % event handlers
    
    methods( Static )
        
        function int = rgb2int( rgb )
            %rgb2int  Convert RGB in [0,1] to Java color integer
            
            int = bitshift( int32( 255 ), 24 ) + ...
                bitshift( int32( 255*rgb(:,1) ), 16 ) + ...
                bitshift( int32( 255*rgb(:,2) ), 8 ) + ...
                bitshift( int32( 255*rgb(:,3) ), 0 );
            
        end % rgb2int
        
        function rgb = int2rgb( int )
            %int2rgb  Convert Java color integer to RGB in [0,1]
            
            int = int - bitshift( int32( 255 ), 24 );
            r = bitshift( int, -16 );
            g = bitshift( int - bitshift( r, 16 ), -8 );
            b = int - bitshift( r, 16 ) - bitshift( g, 8 );
            rgb = double( [r g b] ) / 255;
            
        end % int2rgb
        
    end % static methods
    
end % classdef