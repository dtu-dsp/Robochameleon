function l = lims(x)

if ~isvector(x)
    error('Only works with vectors');
end

l = [min(x) max(x)];
