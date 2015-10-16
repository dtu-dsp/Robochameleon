classdef ButtonBox < uix.Box
    %uix.ButtonBox  Button box base class
    %
    %  uix.ButtonBox is a base class for containers that lay out buttons.
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 985 $ $Date: 2014-09-28 14:55:26 -0400 (Sun, 28 Sep 2014) $
    
    properties( Access = public, Dependent, AbortSet )
        ButtonSize % button size, in pixels
        HorizontalAlignment % horizontal alignment [left|center|right]
        VerticalAlignment % vertical alignment [top|middle|bottom]
    end
    
    properties( Access = protected )
        ButtonSize_ = [60 20] % backing for ButtonSize
        HorizontalAlignment_ = 'center' % backing for HorizontalAlignment
        VerticalAlignment_ = 'middle' % backing for VerticalAlignment
    end
    
    methods
        
        function obj = ButtonBox( varargin )
            
            % Call superclass constructor
            obj@uix.Box()
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
    methods
        
        function value = get.ButtonSize( obj )
            
            value = obj.ButtonSize_;
            
        end % get.ButtonSize
        
        function set.ButtonSize( obj, value )
            
            % Check
            assert( isa( value, 'double' ), 'uix:InvalidPropertyValue', ...
                'Property ''ButtonSize'' must be of type double.' )
            assert( isequal( size( value ), [1 2] ), ...
                'uix:InvalidPropertyValue', ...
                'Size of property ''ButtonSize'' must by 1-by-2.' )
            assert( all( isreal( value ) ) && ~any( isinf( value ) ) && ...
                ~any( isnan( value ) ) && ~any( value <= 0 ), ...
                'uix:InvalidPropertyValue', ...
                'Elements of property ''ButtonSize'' must be real, finite and positive.' )
            
            % Set
            obj.ButtonSize_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.ButtonSize
        
        function value = get.HorizontalAlignment( obj )
            
            value = obj.HorizontalAlignment_;
            
        end % get.HorizontalAlignment
        
        function set.HorizontalAlignment( obj, value )
            
            % Check
            assert( ischar( value ), 'uix:InvalidPropertyValue', ...
                'Property ''HorizontalAlignment'' must be a string.' )
            assert( any( strcmp( value, {'left';'center';'right'} ) ), ...
                'Property ''HorizontalAlignment'' must be ''left'', ''center'' or ''right''.' )
            
            % Set
            obj.HorizontalAlignment_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.HorizontalAlignment
        
        function value = get.VerticalAlignment( obj )
            
            value = obj.VerticalAlignment_;
            
        end % get.VerticalAlignment
        
        function set.VerticalAlignment( obj, value )
            
            % Check
            assert( ischar( value ), 'uix:InvalidPropertyValue', ...
                'Property ''VerticalAlignment'' must be a string.' )
            assert( any( strcmp( value, {'top';'middle';'bottom'} ) ), ...
                'Property ''VerticalAlignment'' must be ''top'', ''middle'' or ''bottom''.' )
            
            % Set
            obj.VerticalAlignment_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.VerticalAlignment
        
    end % accessors
    
end % classdef