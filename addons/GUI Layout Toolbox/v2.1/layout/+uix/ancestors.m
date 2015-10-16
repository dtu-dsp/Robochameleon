function a = ancestors( h )
%uix.ancestors  Get object ancestors
%
%  a = uix.ancestors(h) gets the ancestors of the object h, from top to
%  bottom.  For rooted objects, the highest level ancestor returned is the
%  figure, not the root.

%  Copyright 2009-2014 The MathWorks, Inc.
%  $Revision: 978 $ $Date: 2014-09-28 14:20:44 -0400 (Sun, 28 Sep 2014) $

% Find ancestors
a = gobjects( [0 1] ); %  initialize
p = h.Parent;
while ~isempty( p ) && ~isa( p, 'matlab.ui.Root' )
    a = [p; a]; %#ok<AGROW>
    p = p.Parent;
end

end % uix.ancestors