%> @file clearall.m   
%> @brief Clear all variables but preserve breakpoints
%> 
%> @ingroup roboUtils
%> 
%# store breakpoints
tmp = dbstatus;
save('tmp.mat','tmp')

%# clear all
clear classes %# clears even more than clear all

%# reload breakpoints
load('tmp.mat')
dbstop(tmp)

%# clean up
clear tmp
delete('tmp.mat') 
