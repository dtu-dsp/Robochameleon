function  c  = getClusters( M, coding, shape, phi )

if strcmp(shape,'star')
    phase1=0 + phi;
    phase2=2*pi/M + phi;
    r1 = 1*exp(1j*phase1);  % first radius
    r2 = 2*exp(1j*phase2);  % second radius
    c = [ r1*exp(1i*2*pi/(M/2)*(0:(M/2-1)))  r2*exp(1i*2*pi/(M/2)*(0:(M/2-1)))];
elseif strcmp(shape,'linear')
    c=linspace(-M/2, M/2, M);
elseif iswhole(sqrt(M)) && ~iswhole(log2(M))
    % For QAM
    c = (1:sqrt(M))*2;
    c = c - mean(c);
    c = sum(combvec(c,1j*c));
    c = c*modnorm(c,'avpow',1);
    c = [real(c); imag(c)]';
    [theta, rho] = cart2pol(c(:,1),c(:,2));
    [cx, cy] = pol2cart(theta + phi, rho);
    c = cx+ 1i*cy;
else
    c = qammod(0:M-1,M, phi, coding);
end
c = c*modnorm(c,'avpow',1);
c = c(:);
end

