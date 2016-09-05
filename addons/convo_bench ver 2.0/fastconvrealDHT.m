function z = fastconvrealDHT(x,y)
% Linear Convolution calculated via the Discrete Hartley Transform (DHT).
%
% Input arguments:
%   x is a row vector that contains the real-valued sequence x[n].
%   y is a row vector that contains the real-valued sequence y[n].
% Output Arguments:
%   z : vector containing the real convolution values of x[n] and y[n].

% Make sure x and y are row vectors.
    x = x(:).';
    y = y(:).';

    N = length(x);
    M = length(y);
    L = M+N-1;    % Convolution sequence length.
    
    % Make sure L is even for use with fftreal.m for X and Y in my_DHT.m function.
    if mod(L,2)==0   % if L is already even ...
       x1 = [x zeros(1,L-N)];  % Zero-pad as required to make the length
       y1 = [y zeros(1,L-M)];  % of both sequences equal to L=M+N-1 (even).
    else              % if L is odd ...
       x1 = [x zeros(1,L-N+1)];  % Zero-pad as required to make the length
       y1 = [y zeros(1,L-M+1)];  % of both sequences equal to L= M+N (even).
       L = L + 1;
    end

% Calculate the DHT of x1[n] and y1[n]:
    X = my_DHT(x1);
    Y = my_DHT(y1);

% Next calulate the even and odd parts of Y:
    Yeven = (Y + circshift(fliplr(Y),[0 1]))/2;
    Yodd   = (Y - circshift(fliplr(Y),[0 1]))/2;  

%Calculate the DHT of the output using the given formula:
    Z = X.*Yeven + circshift(fliplr(X),[0 1]).*Yodd;

 % Now calculate the convolution sequence as the inverse DHT transform of Z
    z = 1/L*my_DHT(Z);
    
    % Keep only the valid convolution samples :
    % (this line excludes only the last sample of z[n] when M+N-1 is odd):
    z = z(1:M+N-1);

end
