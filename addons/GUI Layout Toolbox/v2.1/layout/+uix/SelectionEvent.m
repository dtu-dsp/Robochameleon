classdef( Hidden, Sealed ) SelectionEvent < event.EventData
    %uix.SelectionEvent  Event data for selection event
    %
    %  e = uix.SelectionEvent(o,n) creates event data including the old
    %  value o and the new value n.
    
    %  Copyright 2009-2014 The MathWorks, Inc.
    %  $Revision: 978 $ $Date: 2014-09-28 14:20:44 -0400 (Sun, 28 Sep 2014) $
    
    properties( SetAccess = private )
        OldValue % old value
        NewValue % newValue
    end
    
    methods
        
        function obj = SelectionEvent( oldValue, newValue )
            %uix.SelectionEvent  Event data for selection event
            %
            %  e = uix.SelectionEvent(o,n) creates event data including the
            %  old value o and the new value n.
            
            % Set properties
            obj.OldValue = oldValue;
            obj.NewValue = newValue;
            
        end % constructor
        
    end % structors
    
end % classdef