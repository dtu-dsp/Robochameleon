function [bits,bits_] = symb2bits(symb,M,bitorder)

if ~isvector(symb) || ~isa(symb,'uint16')
    error('Input must be a vector (scalar) of type uint16.');
end

[~,symb_range] = findrange(symb);
if nargin<2 || isempty(M) % M is not specified
    log2M_ = nextpow2(symb_range.max);
else
    log2M_ = log2M(M);
end
if symb_range.min<1 || symb_range.max>M
    error('Value out of range. Symbols must be in range 1:%d.',M);
end

if nargin<3
    bitorder = 'lsb-first'; % if bitorder not specified, assume LSB is first
end
lut = logical(arrayfun(@(x)x-48,dec2bin(0:M-1)))'; % LUT for converting decimal to binary LSB first
if strcmpi(bitorder,'lsb-first')
    lut = flipud(lut);
elseif ~strcmpi(bitorder,'msb-first')
    % If order is not 'msb-first' at this point, bitorder is neither of two
    % available options => throw an error.
    error('Bit order can be set to ''lsb-first'' (default) or ''msb-first''.');
end

bits = false(log2M_,numel(symb));
for i=max(2,symb_range.min):symb_range.max
    idx = symb==i; % Find indices for all symbols i
    bits(:,idx) = repmat(lut(:,i),1,nnz(idx)); % Take value from the LUT
end
bits_ = bits(:);
