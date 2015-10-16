function [minmax,minmax_struct] = findrange(x)
% Finds min-max range of a vector/matrix

min_ = min(x);
max_ = max(x);
if ~isscalar(min_) || ~isscalar(max_)
    for i=2:ndims(x)
        min_ = min(min_);
        max_ = max(max_);
    end
end

minmax_struct = struct('min',min_,'max',max_);
minmax = [min_ max_];
