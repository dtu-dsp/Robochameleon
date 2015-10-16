function roboerror(subid,msg,varargin)

narginchk(2,inf);
stack = dbstack;
id = ['robo:' stack(2).name ':' subid];
exception = MException(id,msg,varargin{:});
throwAsCaller(exception);
