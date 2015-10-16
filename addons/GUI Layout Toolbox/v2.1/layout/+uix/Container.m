classdef Container < matlab.ui.container.internal.UIContainer & uix.mixin.Container
    %uix.Container  Container base class
    %
    %  uix.Container is base class for containers that extend uicontainer
    %  and that include various standard properties and template methods.
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 983 $ $Date: 2014-09-28 14:46:55 -0400 (Sun, 28 Sep 2014) $
    
    methods
        
        function obj = Container( varargin )
            
            % Call superclass constructors
            obj@matlab.ui.container.internal.UIContainer()
            obj@uix.mixin.Container()
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
end % classdef