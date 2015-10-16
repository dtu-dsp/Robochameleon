function pSizes = calcPixelSizes( pTotal, mSizes, pMinimumSizes, pPadding, pSpacing )
%calcPixelSizes  Calculate child sizes in pixels
%
%  pSizes = uix.calcPixelSizes(total,mSizes,minSizes,padding,spacing)
%  computes child sizes (in pixels) given total available size (in pixels),
%  child sizes (in pixels and/or relative), minimum child sizes (in
%  pixels), padding (in pixels) and spacing (in pixels).
%
%  Notes:
%  * All children are at least as large as the minimum specified size
%  * Relative sizes are respected for children larger than then minimum
%  specified size
%  * Children may extend beyond the total available size if the minimum
%  sizes, padding and spacing are too large

%  Copyright 2009-2014 The MathWorks, Inc.
%  $Revision: 978 $ $Date: 2014-09-28 14:20:44 -0400 (Sun, 28 Sep 2014) $

n = numel( mSizes ); % number of children

if n == 0
    
    pSizes = zeros( [n 1] );
    
else
    
    % Initialize
    pSizes = NaN( [n 1] );
    
    % Allocate absolute sizes
    a = mSizes >= 0; % absolute
    s = mSizes < pMinimumSizes; % small
    pSizes(a&~s) = mSizes(a&~s);
    pSizes(a&s) = pMinimumSizes(a&s);
    
    % Allocate relative sizes
    pTotalRelative = max( pTotal - 2 * pPadding - (n-1) * pSpacing - ...
        sum( pSizes(a) ), 0 );
    s = pTotalRelative * mSizes / sum( mSizes(~a) ) < pMinimumSizes; % small
    pSizes(~a&s) = pMinimumSizes(~a&s);
    pTotalRelative = max( pTotal - 2 * pPadding - (n-1) * pSpacing - ...
        sum( pSizes(a|s) ), 0 );
    pSizes(~a&~s) = pTotalRelative * mSizes(~a&~s) / sum( mSizes(~a&~s) );
    
end % getPixelPositions