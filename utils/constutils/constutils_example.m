%% Common transmitter code
M = 16; N = 100;
data_in_b = logical(randi([0 1],[log2(M) N]));
data_in_s = bits2symb(data_in_b,M);
% data_in_s = randi(M,[N 1],'uint16'); % Generate data (symbols 1:M obtained from converting binary data)
[c,P] = constref('QAM',M); % Generate reference constellation
[map,demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap

%return;

%% Version with constellation map encoding
c_enc = c(map); % Encode constellation
tx_data = c_enc(data_in_s); % Map symbols to constellation points
rx_data = tx_data; % Transmit
data_out_s = hd_euclid(rx_data,c_enc); % Hard decision mapping of constellation points to symbols
data_out_b = symb2bits(data_out_s,M);
if any(xor(data_in_b,data_out_b))
    warning('Data different.');
else
    fprintf(1,'Data the same.\n');
end

return;

%% Version with symbols mapped to transmitted symbols
% Map data to symbols. For linear mapping, map == demap = 1:M;
tx_symbols = map(data_in_s);
tx_data = c(tx_symbols); % Map symbols to constellation points
rx_data = tx_data; % Transmit
rx_symbols = hd_euclid(rx_data,c); % Hard decision mapping of constellation points to symbols
data_out_s = demap(rx_symbols); % Demap symbols to data
data_out_b = symb2bits(data_out_s,M);
if any(xor(data_in_b,data_out_b))
    warning('Data different.');
else
    fprintf(1,'Data the same.\n');
end



%% Version with averaged constellation power
c_norm = c/sqrt(P); % Normalize constellation
% Map data to symbols. For linear mapping, map == demap = 1:M;
tx_symbols = map(data_in_s);
tx_data = c_norm(tx_symbols); % Map symbols to constellation points
rx_data = tx_data; % Transmit
rx_data_norm = pwr.normpwr(rx_data); % Normalize received constellation
rx_symbols = hd_euclid(rx_data_norm,c_norm);  % Hard decision mapping of constellation points to symbols
data_out_s = demap(rx_symbols); % Demap symbols to data
data_out_b = symb2bits(data_out_s,M);
if any(xor(data_in_b,data_out_b))
    warning('Data different.');
else
    fprintf(1,'Data the same.\n');
end