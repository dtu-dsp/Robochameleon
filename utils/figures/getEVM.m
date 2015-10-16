function [ evm ] = getEVM( srx, constellation )

% Calculate EVM
for q=1:length(srx)
    for j=1:length(constellation)
        ekc(j)=abs(srx(q,:) - constellation(j,:));
    end
    ek(q)=min(ekc.^2);
end
evm=sqrt(sum(ek)/length(srx))*100;

end

