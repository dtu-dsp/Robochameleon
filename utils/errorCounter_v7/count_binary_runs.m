function [counts0,counts1] = count_binary_runs(x)

if ~isvector(x) || ~islogical(x)
    error('Input must be a logical vector.');
end

N_max = ceil(numel(x)/2);
counts0 = nan(N_max,1);
counts1 = nan(N_max,1);
idx_0 = 0;
idx_1 = 0;

x(end+1) = ~x(end); % Append one different bit to count correctly the last run
current = x(1);
idx = 1;
for i=2:numel(x);
    if x(i)~=current % new bit is flipped => append new run
        if current % if was 1
            idx_1 = idx_1+1;
            counts1(idx_1) = i-idx;
        else
            idx_0 = idx_0+1;
            counts0(idx_0) = i-idx;
        end
        current = ~current;
        idx = i;
    end
end

counts0 = counts0(1:idx_0);
counts1 = counts1(1:idx_1);
