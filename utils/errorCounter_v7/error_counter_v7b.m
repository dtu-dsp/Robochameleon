function [ber,ser,ber_block,ser_block,blockmap,err_bits,totalbits,err_symb,totalsymb,ORIG_SYMBOLS] = error_counter_v7b(RECEIVED_DATA,REFERENCE_DATA,param)

L_block_s = param.L; % Error counter block length, symbols; set to inf for one block
M = param.M;
coding = param.coding;
%TODO Parametrize
ber_th = 0.1; % BER threshold above which contribution of a block is rejected
% err_th_rot = (0.25/ber_th-1)/2; % Tolerance (%) for BER increase between consecutive blocks, not requiring to try all de-map permutations

if nargout<10
    RETURN_REFERENCE_SEQUENCE = 0;
else
    RETURN_REFERENCE_SEQUENCE = 1;
end

%% Reference data
if ~isvector(REFERENCE_DATA)
    error('Reference data must be a vector.');
end
if islogical(REFERENCE_DATA)
    % Binary sequence -- binary delay & add mode
    mode = 0;
    fprintf(1,'Error counter mode: binary delay & add.\n');
    D_tx_b = REFERENCE_DATA(:)';
    [~,demap] = constmap('QAM',M,'linear');
elseif isa(REFERENCE_DATA,'uint16')
    % Integer sequence -- synchronized symbols
    mode = 1;
    fprintf(1,'Error counter mode: symbols.\n');
    D_tx_b = symb2bits(REFERENCE_DATA,M); % D_tx_b is recreated from symbols
    % TODO Any map can be used here
    [~,demap] = constmap('QAM',M, coding); % Create Gray constellation map/demap
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
L_tx_s = size(D_tx_b,2);
L_tx_b = numel(D_tx_b); %L_tx_s*log2M==L_tx_b

log2M_ = log2M(M);    
L_block_s = min(L_block_s,L_rx_s); % In case of L_block = inf

N_loop = round(L_rx_s/L_block_s); % Number of error counter loop iterations

[c,P] = constref('QAM',M); % Generate reference constellation for symbol decisions
c = c/sqrt(P);
decision = @hd_euclid; % Symbol decision function: hd_euclid, sd_kmeans



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

fprintf(1,'Error counter: %d block(s), %d de-map permutation(s).\n',N_loop,N_demap);
%% Error counter loop
idx_markers = [0 cumsum(totalsymb)];
for i=1:N_loop % For each block
    %fprintf(1,'    Block %d, de-map permutation',i);
    fprintf('.');

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
                    for k=1:log2M_ % For each column (no. of columns == log2M)
                        tmp = sumbitxor(D_tx_b_rep,rx_bits(:,k)); % Check BER
                        [badbits_,delay(k,j)] = min(tmp);
                        badbits(j,i) = badbits(j,i) + badbits_;
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
                D_tx_b_ref = false(totalsymb(i),log2M_); % Create transposed for faster column access
                for k=1:log2M_
                    D_tx_b_ref(:,k) = D_tx_b_rep(delay(k)+(0:totalsymb(i)-1));
                end
                D_tx_b_ref = D_tx_b_ref';
            case 1
                D_tx_b_ref = D_tx_b_rep(:,delay+(0:totalsymb(i)-1));
        end
        
        if RETURN_REFERENCE_SEQUENCE
            [~,mp] = sort(demap_);
            ORIG_SYMBOLS(idx) = mp(bits2symb(D_tx_b_ref,M));
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
fprintf(1,'.\n');
%perm % Constellation permutations

ber_block = err_bits./totalbits;
blockmap = ber_block<ber_th;
ber = sum(err_bits(blockmap))/sum(totalbits(blockmap));


ser_block = err_symb./totalsymb;
ser = sum(err_symb(blockmap))/sum(totalsymb(blockmap));
