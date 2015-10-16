function obj = Empty( varargin )
%uix.Empty  Create an empty space
%
%   obj = uix.Empty() creates a placeholder that can be used to add
%   gaps between elements in layouts.
%
%   obj = uix.Empty(param,value,...) also sets one or more property
%   values.
%
%   See the <a href="matlab:doc uix.Empty">documentation</a> for more detail and the list of properties.
%
%   Examples:
%   >> f = figure();
%   >> box = uix.HBox( 'Parent', f );
%   >> uicontrol( 'Parent', box, 'Background', 'r' )
%   >> uix.Empty( 'Parent', box )
%   >> uicontrol( 'Parent', box, 'Background', 'b' )

%   Copyright 2009-2014 The MathWorks, Inc.
%   $Revision: 919 $ $Date: 2014-06-03 11:05:38 +0100 (Tue, 03 Jun 2014) $

% Call uix constructor
obj = matlab.ui.control.UIControl( varargin{:}, 'Visible', 'off' );

end % uix.Empty