

% EVM Analysis - Calculate the EVM of a given set of constellation points

function [EVM, BER_evm, SNR, Qfactor] = EVM_Analysis(Out,M, Type)
 

         ConstSymb = constref('QAM', M).';
         N = sum(norm(ConstSymb).^2)/M;
         ConstSymb = ConstSymb/sqrt(N); 
        
        switch Type
            case 'Ideal'
                 IdealConstX = ConstSymb;
                 IdealConstY = ConstSymb;
            case 'NonIdeal'
                IdealConstX = kmeans_v1(ConstSymb, Out.X, 10);
                %IdealConstX = centersX(1,:) +j*centersX(2,:);
                IdealConstY = kmeans_v1(ConstSymb, Out.Y, 10);
                %IdealConstY = centersY(1,:) +j*centersY(2,:);
            otherwise
                error('\nType of constellation (Ideal or NonIdeal) not specified for EVM calculation.')
        end

% Deciding symbols:
        Out.SymbX = SymbolDecisor(IdealConstX, Out.X);
        Out.SymbY = SymbolDecisor(IdealConstY, Out.Y);

 
% EVM calculation:
% Reference: On the Extended Relationships Among EVM, BER and SNR as
% Performance Metrics. (International Conference on ELectrical and Computer
% Engineering, ICECE 2006)
            
         

% EVM of X polarization:
        Pxy = M*mean(abs(IdealConstX));
        EVM_X = sqrt((Out.X-Out.SymbX)*(Out.X-Out.SymbX)'/length(real(Out.X)))/sqrt(sum(sum(Pxy))/M);
        EVM_X = EVM_X*100;              % EVM RMS
        EVM_X = EVM_X/100;
        SNRbX = 1/(EVM_X^2)/log2(M);         % Estimated Signal-to-noise ratio
        SNRbX_dB = 10*log10(SNRbX)

% EVM of Y polarization:
        Pxy = M*mean(abs(IdealConstY));
        EVM_Y = sqrt((Out.Y-Out.SymbY)*(Out.Y-Out.SymbY)'/length(real(Out.Y)))/sqrt(sum(sum(Pxy))/M);
        EVM_Y = EVM_Y*100;              % EVM RMS
        EVM_Y = EVM_Y/100;
        SNRbY = 1/(EVM_Y^2)/log2(M);         % Estimated Signal-to-noise ratio
        SNRbY_dB = 10*log10(SNRbY)

% Estimated BER from EVM
        L = log2(M);
        %M = 16;
        EVM.X = EVM_X;
        EVM.Y = EVM_Y

        BER_evm.X = ((1-1/L)/log2(L))*erfc(sqrt(3*log2(L)./(((L^2)-1).*((EVM.X).^2)*log2(M))));
        BER_evm.Y = ((1-1/L)/log2(L))*erfc(sqrt(3*log2(L)./(((L^2)-1).*((EVM.Y).^2)*log2(M))))
        SNR.SNRbX = SNRbX_dB;
        SNR.SNRbY = SNRbY_dB;
        
        Qfactor.X = 20*log10(sqrt(2)*erfcinv(2*BER_evm.X));
        Qfactor.Y = 20*log10(sqrt(2)*erfcinv(2*BER_evm.Y))
end
