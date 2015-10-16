function log2M = log2M(M)

if ~isscalar(M) || ~isreal(M) || M<1 || ~isfinite(M)
    error('M must be a positive real finitie scalar.');
end
log2M = log2(M);
if ~iswhole(log2M) || log2M<1
    error('M must be a number 2^k, where k is a positive integer.');
end
