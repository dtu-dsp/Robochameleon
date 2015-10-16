function x=gen_prbs(n)
% x=gen_prbs(n)
% 2^n-1-bit PRBS sequence based on the polynomial with minimum # XORs.
% n: PRBS length

% Primitive polynomial employed by SHF
switch n
    case 7
        g = [7 6];
    case 15
        g = [15 14];
    case 23
        g  =[23 18];
    case 31
        g = [31 28];
    otherwise
        error('Allowed lengths: 2^{7|15|23|31}-1');
end

% PRBS Generation
z = zeros(1,2^n-1);
z(1)=1;
for i=(n+1):(2^n-1)
    q=z(i-g(1));
    for j=2:length(g)
        q=xor(q,z(i-g(j)));
    end
    z(i) = q;
end
z = [z 0];
z=z(:);
x = logical(z(1:2^n-1));

end
