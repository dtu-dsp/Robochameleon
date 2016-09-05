function [minmax,minmax_struct] = findrange(x)
% Finds min-max range of a vector/matrix

min_ = min(x);
max_ = max(x);
minmax = [min_; max_];
minmax_struct = struct('min',min_,'max',max_);
