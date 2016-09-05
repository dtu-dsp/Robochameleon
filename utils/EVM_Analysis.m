%> @file EVM_Analysis.m
%> @brief Performance analysis of square QAM based on the EVM of symbols.
%>
%> __Observations__
%>
%> Be aware that the performance estimated may deviate from the real
%> performance, mainly for low SNR values and high order QAMs. (see
%> reference [1])
%>
%> __Example__
%> @code
%>   M = 4;
%>   L = 1000;
%>   x = (2*randi([0 1],1,L)-1)+1i*(2*randi([0 1],1,L)-1); %L QPSK symbols
%>   n = 0.1*(randn(1,L)+1i*randn(1,L)); % Gaussian Noise
%>   y = x + n; % L constellation noisy data points
%>
%>   [EVM, BER_evm, BER_theory, SNR, EbN0, Qfactor]= EVM_Analysis(y, M);
%>   [EVM, BER_evm, BER_theory, SNR, EbN0, Qfactor]= EVM_Analysis(y, M, 'type', 'nonIdeal');
%>   [EVM, BER_evm, BER_theory, SNR, EbN0, Qfactor]= EVM_Analysis(y, M, 'type', 'nonIdeal', 'iterations', 50);
%> @endcode
%>
%> References
%>
%> [1] On the Extended Relationships Among EVM, BER and SNR as
%> Performance Metrics. (International Conference on ELectrical and Computer
%> Engineering, ICECE 2006)
%>
%> @author Edson Porto da Silva
%> @version 1

%> @brief Allows QAM performance estimation based on EVM of noisy data.
%>
%> @param inputData signal_interface(Nss=1), vector|matrix of const. points
%> @param M QAM constellation order
%> @param type NonIdeal uses k-means to update
%>             the reference constellation based on the actual clusters in
%>             the data. {'ideal'|'nonIdeal'}. [Default: 'ideal']
%> @param iterations Maximum number of allowed k-means iterations.
%> @retval EVM Error vector magnitude.
%> @retval BER_evm BER estimated from EVM.
%> @retval BER_theory BER estimated from SNR(evm), according to MATLAB's "berawgn."
%> @retval SNR_dB Signal-to-noise ratio estimated from EVM, in dB.
%> @retval EbN0_dB Signal-to-noise ratio per bit estimated from EVM, in dB.
%> @retval Qfactor_dB Q^2-factor estimated from BER_evm, in dB.
function [EVM, BER_evm, BER_theory, SNR_dB, EbN0_dB, Qfactor_dB, Out] = EVM_Analysis(inputData, M, varargin)

% default mode to choose the reference constellation:
type = 'ideal';
iterations = 0;
constSymb = constref('QAM', M).';

% configure optional variables:
if nargin > 2
    for argidx = 1:2:nargin-2
        switch varargin{argidx}
            case 'type'
                type = varargin{argidx+1};
            case 'iterations'
                iterations = varargin{argidx+1};
            case 'constellation'
                constSymb = varargin{argidx+1};
        end
    end
end

% Define variables:
L = log2(M);

N = sum(norm(constSymb).^2)/M;
constSymb = constSymb/sqrt(N);

if isa(inputData,'signal_interface') % In case the signal provided is a signal_interface instance
    if inputData.Nss ~= 1
        robolog('This block requires an input with number of samples per symbol equals to 1.', 'ERR');
    end
    SigNumber = inputData.N;
else % In case the signal provided is a arbitrary matrix whose length is the number of symbols
    % we want the different components of inputData to be disposed in columns
    if size(inputData,1) ~= length(inputData)
        inputData = inputData.';
    end
    SigNumber = size(inputData,2);
end
% Allocate memory for results:
EVM        = nan(1,SigNumber);
SNR_dB     = nan(1,SigNumber);
EbN0_dB    = nan(1,SigNumber);
Qfactor_dB = nan(1,SigNumber);
BER_evm    = nan(1,SigNumber);
BER_theory = nan(1,SigNumber);
Out        = nan(length(inputData(:,1)),SigNumber);

for sigCol = 1:SigNumber % perform the EVM analysis for each signal component of signal_interface
    constPoints = inputData(:,sigCol).'/sqrt(pwr.meanpwr(inputData(:,sigCol))); % Transpose to work with row vectors
    switch type
        case 'ideal'
            idealConst = constSymb;
            if iterations ~= 0
                robolog('EVM calculation assumes ideal constellation (k-means disabled!).','WRN')
            end
        case 'nonIdeal'
            idealConst = kmeans_v1(constSymb, constPoints, 'iterations', iterations);
        otherwise
            robolog('Type of constellation (ideal or nonIdeal) not specified for EVM calculation. Assuming ideal constellation as default','WRN')
            idealConst = constSymb;
    end
    decidedIndex = hd_euclid(constPoints, idealConst);
    decidedSymb = idealConst(decidedIndex);
    
    Out(:, sigCol)=decidedSymb;
    
    % EVM calculation:
    Pxy = M*mean(abs(idealConst));
    EVM(sigCol) = sqrt((constPoints-decidedSymb)*(constPoints-decidedSymb)'/length(constPoints))/sqrt(sum(sum(Pxy))/M); % EVM definition [1].
    
    SNR_dB(sigCol)  = 10*log10(1/(EVM(sigCol)^2));      % Estimated signal-to-noise ratio (SNR) in dB
    EbN0            = 1/(EVM(sigCol)^2)/log2(M);        % Estimated signal-to-noise ratio (SNR) per bit
    EbN0_dB(sigCol) = 10*log10(EbN0);                   % Estimated signal-to-noise ratio (SNR) per bit in dB
    BER_evm(sigCol) = ((1-1/L)/log2(L))*erfc(sqrt(3*log2(L)./(((L^2)-1).*((EVM(sigCol)).^2)*log2(M))));
    BER_theory(sigCol) = berawgn(EbN0_dB(sigCol),'qam',M,'coherent');
    Qfactor_dB(sigCol) = 20*log10(sqrt(2)*erfcinv(2*BER_evm(sigCol)));
end

if length(SNR_dB)== 2
    RowsTag = ['Pol.(X) Pol.(Y)'];
else
    for nResults = 1:length(SNR_dB)
        if nResults ~= 1
            RowsTag = [RowsTag ' SignalCol.' num2str(nResults)];
        else
            RowsTag = 'SignalCol(1)';
        end
    end
end
printmat([SNR_dB' EbN0_dB' BER_theory' BER_evm' Qfactor_dB'],...
    'EVM results', RowsTag , 'SNR(dB) EbN0(dB) BER_theory BER_evm Q^2(dB)' )

end