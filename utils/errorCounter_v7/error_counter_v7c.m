%> @file error_counter_v7c.m
%> @brief General error counter
%>
%> Generic error counter.  Takes any received sequence, any reference data,
%> and counts errors.  The data is partitioned into blocks of variable 
%> length, and each block is synchronized, mapped, and counted independently.  
%> It is not optimized for any case in particular, and  faster algorithms 
%> may be available.  See BERT_v1 for other options and usage example.
%> 
%> @see BERT_v1
%> @see const_ref.m
%> @see hd_euclid.m
%> @see sd_kmeans.m
%> @see sumbitxor.m
%>
%> @param RECEIVED_DATA received data, normalized to unity power
%> @param REFERENCE_DATA reference data.  For constellation orders >=2, if this is type logical, counter constructs symbols assuming binary delay & add. If this is type uint16, counter assumes they are symbols.
%> @param param.L Counter block length, set to inf for one block (required)
%> @param param.M Constellation order (required)
%> @param param.const_type Constellation type (default QAM, see const_ref.m for options)
%> @param param.coding coding type (required) {'gray' | 'bin'} 
%> @param param.decision_type decision type (default hard) {'hard' | 'soft'}
%> @param param.ber_th BER threshold (throw away blocks with worse BERs than this) (default 0.1)
%>
%> @retval ber bit error rate of full sequence
%> @retval ser symbol error rate of full sequence
%> @retval ber_block bit error rate per block (array)
%> @retval ser_block symbol error rate per block (array)
%> @retval blockmap logical array of blocks with ber<param.ber_th
%> @retval err_bits number of bit errors
%> @retval totalbits number of bits counted
%> @retval err_symb number of symbol errors
%> @retval totalsymb number of symbols counted
%> @retval ORIG_SYMBOLS symbol sequence used for counting (optional)
%> @retval RX_SYMBOLS symbol sequence counted (optional)
%> 
%> @author Robert Borkowski
function [ber,ser,ber_block,ser_block,blockmap,err_bits,totalbits,err_symb,totalsymb,ORIG_SYMBOLS, RX_SYMBOLS] = error_counter_v7c(RECEIVED_DATA,REFERENCE_DATA,param)
%Note: this function operates the same as way as error_counter_v7b, but allows user-specified constellation type (see const_ref.m for options) and
%user-specified decision type ('hard', 'soft')
%defaults to QAM and hard decision
L_block_s = param.L; % Error counter block length, symbols; set to inf for one block
M = param.M;
coding = param.coding;
if isfield(param, 'const_type'), const_type=param.const_type;
else const_type='QAM'; end
if isfield(param, 'decision_type'), decision_type=param.decision_type;
else decision_type='hard'; end

if isfield(param, 'ber_th'), ber_th=param.ber_th;
else ber_th=0.1; end
% err_th_rot = (0.25/ber_th-1)/2; % Tolerance (%) for BER increase between consecutive blocks, not requiring to try all de-map permutations

if nargout<10
    RETURN_REFERENCE_SEQUENCE = 0;
else
    RETURN_REFERENCE_SEQUENCE = 1;
end

if nargout<11
    RETURN_RECEIVED_SEQUENCE = 0;
else
    RETURN_RECEIVED_SEQUENCE = 1;
end

%% Reference data
if ~isvector(REFERENCE_DATA)
    error('Reference data must be a vector.');
end
if islogical(REFERENCE_DATA)
    % Binary sequence -- binary delay & add mode
    mode = 0;
    robolog('Error counter mode: binary delay & add.');
    D_tx_b = REFERENCE_DATA(:)';
    [~,demap] = constmap(const_type,M,'linear');
elseif isa(REFERENCE_DATA,'uint16')
    % Integer sequence -- synchronized symbols
    mode = 1;
    robolog('Error counter mode: symbols.');
    D_tx_b = symb2bits(REFERENCE_DATA,M); % D_tx_b is recreated from symbols
    % TODO Any map can be used here
    [~,demap] = constmap(const_type,M, coding); % Create Gray constellation map/demap
else
    error('Reference data can be of type logical (binary delay & add) or uint16 (symbols).');
end

% FIXME AUTOMATIC MAP
automap = false; % DO NOT SET TO TRUE FOR NOW
if automap, demap = demap(:,1); end
N_demap = size(demap,2);


L_rx_s = size(RECEIVED_DATA,1);
if RETURN_REFERENCE_SEQUENCE
    ORIG_SYMBOLS = zeros(size(RECEIVED_DATA),'uint16');
end
if RETURN_RECEIVED_SEQUENCE
    RX_SYMBOLS = zeros(size(RECEIVED_DATA),'uint16');
end
L_tx_s = size(D_tx_b,2);
L_tx_b = numel(D_tx_b); %L_tx_s*log2M==L_tx_b

log2M_ = log2M(M);    
L_block_s = min(L_block_s,L_rx_s); % In case of L_block = inf

N_loop = round(L_rx_s/L_block_s); % Number of error counter loop iterations

[c,P] = constref(const_type,M); % Generate reference constellation for symbol decisions
c = c/sqrt(P);
switch decision_type
    case 'hard'
        decision = @hd_euclid; % Symbol decision function: hd_euclid, sd_kmeans
    case 'soft'
        decision = @sd_kmeans;
    otherwise
        robolog('Unrecognized decision type', 'ERR')
end



badbits = nan(N_demap,N_loop);
%     badsymb = nan(N_loop,N_demap);
badsymb = nan(1,N_loop);


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

perm = nan(N_loop,1);

robolog('Error counter: %d block(s), %d de-map permutation(s).',N_loop,N_demap);
%% Error counter loop
idx_markers = [0 cumsum(totalsymb)];
for i=1:N_loop % For each block
    %fprintf(1,'    Block %d, de-map permutation',i);
    %fprintf('.');

    idx = idx_markers(i)+1:idx_markers(i+1); % Sliding data indices
    rx_points = decision(RECEIVED_DATA(idx),c); % Make decision on the received signal

    if ~automap % Fixed constellation map

        switch mode
            case 0
                delay = nan(log2M_,N_demap);
            case 1
                delay = nan(1,N_demap);
        end

        if i==1 %% FIXME Added for parfor
            jj = 1:N_demap; % On first iteration try all possible map rotations
        end
        for j=jj % Try different constellation rotations
            %fprintf(1,' %d',j);
            demap_ = demap(:,j); % Select one of the de-maps
            rx_symbols = demap_(rx_points); % De-map received symbols
            rx_bits = symb2bits(rx_symbols,M); % Convert to bits

            switch mode
                case 0 % Binary delay & add mode
                    rx_bits = rx_bits'; % Transpose for faster column access
                    badbits(j,i) = 0;
                    D_tx_b_ref = false(totalsymb(i),log2M_); % Create transposed for faster column access
                    for k=1:log2M_ % For each column (no. of columns == log2M)
                        tmp = sumbitxor(D_tx_b_rep,rx_bits(:,k)); % Check BER
                        [tmp_badbits(1), tmp_idx(1)] = min(tmp); % not negated
                        [tmp_badbits(2), tmp_idx(2)] = max(tmp); % negated
                        tmp_badbits(2) = totalsymb(i) - tmp_badbits(2);
                        [badbits_, which] = min(tmp_badbits);
                        delay(k,j)=tmp_idx(which);
                        
                        %[badbits_,delay(k,j)] = min(tmp);
                        badbits(j,i) = badbits(j,i) + badbits_;
                       
                        D_tx_b_ref(:,k) = logical(which - 1 - D_tx_b_rep(delay(k, j)+(0:totalsymb(i)-1)));
                        
                    end

                case 1 % Symbols mode
                    tmp = sumbitxor(D_tx_b_rep(:),rx_bits(:));
                    tmp = tmp(1:log2M_:end); % Step by log2M_ (one symbol)
                    [badbits(j,i),delay(j)] = min(tmp);
            end

            if i>1 && badbits(j,i)/totalbits(i)<=ber_th
                % If iteration>1 and number of errors does not exceed
                % err_th_rot then do not try remaining map rotations.
                break
            end
        end
        %fprintf(1,'.\n');
        
        % On subsequent iterations order rotations according to the
        % number of incorrect bits in the previous iteration. In
        % this way we can reduce the number of rotations to try.
        [~,jj] = sort(badbits(:,i)'); %#ok<TRSRT>

        perm(i) = jj(1);
        demap_ = demap(:,perm(i));
        rx_symbols = demap_(rx_points); % De-map received symbols
        rx_bits = symb2bits(rx_symbols,M); % Convert to bits

        err_bits(i) = badbits(perm(i),i);
        delay = delay(:,perm(i));
        switch mode
            case 0
                %we have already calculated this
                D_tx_b_ref = D_tx_b_ref';
            case 1
                D_tx_b_ref = D_tx_b_rep(:,delay+(0:totalsymb(i)-1));
        end
        
        if RETURN_REFERENCE_SEQUENCE
            [~,mp] = sort(demap_);
            ORIG_SYMBOLS(idx) = mp(bits2symb(D_tx_b_ref,M));
        end
        if RETURN_RECEIVED_SEQUENCE
            RX_SYMBOLS(idx) = rx_symbols;
        end
        
        ber_map = sparse(xor(D_tx_b_ref,rx_bits)); % BER error map
        ser_map = logical(sum(ber_map,1)); % SER error map
%         [err_distances,err_lengths] = count_binary_runs(ser_map); % Error statistics: runs of errors/no errors
%         figure,hist(err_distances,25)
%         title('Distance between errorneous symbols (symbol error bursts)');
%         figure,hist(err_lengths,25)
%         title('Lengths of symbol error bursts');
        err_symb(i) = nnz(ser_map); % Number of symbol errors


    end


%     else % Auto map
%         data_out_s = demap(rx_symbols);
%         [~,data_out_b] = symb2bits(data_out_s,M);
%         %size(D_tx_b2,2)==size(data_out_b)
%         
%         for j=1:size(D_tx_b2,2);
%             x = sumbitxor(D_tx_b2(:,j),data_out_b(:,j));
%             [badbits_pos,loc_pos] = min(x);
%             [badbits_neg,loc_neg] = max(x); % negative logic detector
%             badbits_neg = L_block-badbits_neg;
%             if badbits_neg<badbits_pos % Negative logic detected
%                 fprintf('Bit %d is inverted. Updating constellation de-map.\n',j);
%                 demap = bitxor(demap-1,2^(j-1))+1; % Flip j-th bit for every symbol in the map
%                 data_out_b(:,j) = ~data_out_b(:,j); % Flip j-th bit for every symbol in the received data (optional)
%                 badbits_ = badbits_neg; % Assign number of bits
% %                 loc_ = 
%             else
%                 badbits_ = badbits_pos;
%             end
%             badbits(i) = badbits(i) + badbits_;
%         end
%     end



end
%fprintf(1,'.\n');
%perm % Constellation permutations

ber_block = err_bits./totalbits;
blockmap = ber_block<ber_th;
ber = sum(err_bits(blockmap))/sum(totalbits(blockmap));


ser_block = err_symb./totalsymb;
ser = sum(err_symb(blockmap))/sum(totalsymb(blockmap));
