function varargout = defaultargs(defaults,inputs)

ninputs = length(inputs);
if ~iscell(defaults)
    defaults = {defaults};
end

varargout = defaults;
varargout(1:ninputs) = inputs(1:ninputs);
