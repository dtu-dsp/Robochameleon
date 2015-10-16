function symb = bits2symb(bits,M,bitorder)

if ~islogical(bits)
    error('Bits must be of type logical.');
end

if nargin<2 || isempty(M) % if M not specified, or is an empty matrix
    log2M_ = size(bits,1); % log2(M) is equal to first dimension of bits matrix
else % M specified
    log2M_ = log2M(M); % log2(M) is computed from M
    N = size(bits,1);
    if all(size(bits)>1) && N~=log2M_ %% if given a matrix whose first dimension disagrees with log2(M) of given M
        error('First dimension of input bit matrix (%d) does not agree with log2(M) (%d).',N,log2M_);
    end
    bits = reshape(bits,log2M_,[]);
end

if nargin<3
    bitorder = 'lsb-first'; % if bitorder not specified, assume LSB is first
end
mult = 2.^(0:log2M_-1)'; % multipliers for LSB
if strcmpi(bitorder,'msb-first') % if order is MSB, flip multipliers
    mult = flipud(mult);
elseif ~strcmpi(bitorder,'lsb-first')
    % If order is not 'lsb-first' at this point, bitorder is neither of two
    % available options => throw an error.
    error('Bit order can be set to ''lsb-first'' (default) or ''msb-first''.');
end

symb = uint16(sum(bsxfun(@times,bits,mult),1)')+1;
