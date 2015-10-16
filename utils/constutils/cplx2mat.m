function y = cplx2mat(x)

x = x(:);
y = [real(x) imag(x)];
