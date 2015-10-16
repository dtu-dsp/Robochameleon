function mymap = colormapRGBmatrices( N, rm, gm, bm)
  x = linspace(0,1, N);
  rv = interp1( rm(:,1), rm(:,2), x);
  gv = interp1( gm(:,1), gm(:,2), x);
  mv = interp1( bm(:,1), bm(:,2), x);
  mymap = [ rv', gv', mv'];
  %exclude invalid values that could appear
  mymap( isnan(mymap) ) = 0;
  mymap( (mymap>1) ) = 1;
  mymap( (mymap<0) ) = 0;
end