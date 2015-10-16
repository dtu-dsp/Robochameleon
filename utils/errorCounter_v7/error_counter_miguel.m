function [ber,ser,ber_block,ser_block,blockmap,err_bits,totalbits,err_symb,totalsymb,ORIG_SYMBOLS, RX_SYMBOLS] = error_counter_v7b(RECEIVED_DATA,REFERENCE_DATA,param)


%% Param check
if ~isvector(REFERENCE_DATA)
    error('Reference data must be a vector.');
end

%% Get parameters
L_block_s = param.L; % Error counter block length, symbols; set to inf for one block
M = param.M;
coding = param.coding;
ber_th = 0.1; % BER threshold above which contribution of a block is rejected
D_tx_b = REFERENCE_DATA(:)';
[~,demap] = constmap('QAM',M, coding);
demap=demap(:,1);
N_demap = size(demap,2);
log2M_ = log2M(M);
L_rx_s = size(RECEIVED_DATA,1);

%% Variable initialization
ORIG_SYMBOLS = zeros(size(RECEIVED_DATA),'uint16');
RX_SYMBOLS = zeros(size(RECEIVED_DATA),'uint16');
L_tx_s = size(D_tx_b,2);
L_block_s = min(L_block_s,L_rx_s); % In case of L_block = inf
N_loop = round(L_rx_s/L_block_s); % Number of error counter loop iterations
[c,P] = constref('QAM',M); % Generate reference constellation for symbol decisions
c = c/sqrt(P);
decision = @sd_kmeans; % Symbol decision function: hd_euclid, sd_kmeans

err_bits = nan(1,N_loop);
err_symb = nan(1,N_loop);
totalsymb = repmat(L_block_s,1,N_loop-1);
totalsymb = [totalsymb L_rx_s-sum(totalsymb)];
totalbits = log2M_*totalsymb; % Total number of bits

% Repeat tx data to account for possible wrap-around in the rx data.
% Take maximum of first and last block length to take into account
% possible variation in the last block length.
N_tx = ceil(max(totalsymb(1),totalsymb(end))/(L_tx_s-1))+1;
D_tx_b_rep = repmat(D_tx_b,1,N_tx);

fprintf(1,'Error counter: %d block(s).\n',N_loop);
%% Error counter loop
idx_markers = [0 cumsum(totalsymb)];
for i=1:N_loop % For each block
    idx = idx_markers(i)+1:idx_markers(i+1); % Sliding data indices
    D_tx_b_ref = false(totalsymb(i),log2M_); % Create transposed for faster column access
    rx_symbols = decision(RECEIVED_DATA(idx),c); % Make decision on the received signal
    delay = nan(1,N_demap);
    rx_bits = symb2bits(rx_symbols,M); % Convert to bits
    rx_bits = rx_bits'; % Transpose for faster column access
    err_bits(i) = 0;
    for k=1:log2M_ % For each column (no. of columns == log2M)
        tmp = sumbitxor(D_tx_b_rep,rx_bits(:,k)); % Check BER
        [tmp_badbits(1), tmp_idx(1)] = min(tmp); % not negated
        [tmp_badbits(2), tmp_idx(2)] = max(tmp); % negated
        tmp_badbits(2) = totalsymb(i) - tmp_badbits(2);
        [badbits_, which] = min(tmp_badbits);
        delay(k) = tmp_idx(which);
        err_bits(i) = err_bits(i) + badbits_;
        % Construct original bit sequence
        D_tx_b_ref(:,k) = logical(which - 1 - D_tx_b_rep(delay(k)+(0:totalsymb(i)-1)));
    end
    D_tx_b_ref = D_tx_b_ref';
    ORIG_SYMBOLS(idx) = bits2symb(D_tx_b_ref, M);
    RX_SYMBOLS(idx) = rx_symbols;
    
    rx_bits = symb2bits(rx_symbols,M); % Convert to bits
    
    ber_map = sparse(xor(D_tx_b_ref,rx_bits)); % BER error map
    ser_map = logical(sum(ber_map,1)); % SER error map
    
    err_symb(i) = nnz(ser_map); % Number of symbol errors
    %if err_bits(i)/totalbits(i) > ber_th
    fprintf([num2str(err_bits(i)) '|']);
end
fprintf(1,'\n');

ber_block = err_bits./totalbits;
blockmap = ber_block<.1;
if any(blockmap==0)
    disp(['Excluded ' num2str(sum(blockmap==0)) ' blocks accounting for ' num2str(sum(err_bits(~blockmap))) ' errors']);
end
ber = sum(err_bits(blockmap))/sum(totalbits(blockmap));
ser_block = err_symb./totalsymb;
ser = sum(err_symb(blockmap))/sum(totalsymb(blockmap));
