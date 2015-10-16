function robowarning(subid,msg,varargin)
fprintf('Does''t work yet.');
return

narginchk(2,inf);
evalin('caller',['warning([''robo:'' mfilename ' subid ':' msg

stack = dbstack;
id = ['robo:' stack(2).name ':' subid];
