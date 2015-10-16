function plotCool(x,y,varargin)
%close all

error(nargchk(1,Inf,nargin));

% check the arguments
if ~isnumeric(x),
    error('Numeric argument expected') ;
end

if ischar(y)
    y=x;
    x=1:length(x);
end

% Get the color
col='b';
markf=false;
for i=1:length(varargin)
    if strcmp(varargin{i}, 'color')
        col=varargin{i+1};
    elseif strcmp(varargin{i}, 'MarkerFace')
        markf=true;
    end
end

resampleFactor=30;
xr = linspace(x(1), x(end), length(y)*resampleFactor);
yr = resample(y ,resampleFactor+1,1);
yr = yr(1:length(y)*resampleFactor);

plot(xr, yr, varargin{:})
if (markf)
    hold on
    hh = plot(x,y, 'o', 'color', col, 'MarkerFace', col);
    hasbehavior(hh,'legend',false)
end

end

