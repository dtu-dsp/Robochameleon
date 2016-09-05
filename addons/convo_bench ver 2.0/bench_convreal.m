% This routine compares the time needed to execute various real-valued signal convolutions. 
% Namely, matlab's built-in conv.m and custom functions: 
%
% 1) fastconvDFT.m,    
% 2) fastconvrealDFT.m,  
% 3) fastconvrealDHT.m.

clc; clear; close all;

% Various sizes of input signals:
N = 2.^(3:17);
L = length(N); 

time_conv                     = zeros(1,L);
time_fastconvDFT       = zeros(1,L);
time_fastconvrealDFT = zeros(1,L);
time_fastconvrealDHT = zeros(1,L);

for k=1:L
    
     x = randn(1,N(k));
     y = randn(1,N(k));    
    
     tic
     z1 = conv(x,y);
     time_conv(k) = toc;
    
     tic
     z2 = fastconvDFT(x,y);
     time_fastconvDFT(k) = toc;
    
     tic
     z3 = fastconvrealDFT(x,y);
     time_fastconvrealDFT(k) = toc;   
    
     tic
     z4 = fastconvrealDHT(x,y);
     time_fastconvrealDHT(k) = toc;   
    
    k
      
end

%% Now plot the results.
figure('Name','Benchmarking of FFT and DFT execution');
semilogy(log2(N),time_conv,'*-');
hold on;
semilogy(log2(N),time_fastconvDFT,'r*-');
semilogy(log2(N),time_fastconvrealDFT,'g*-');
semilogy(log2(N),time_fastconvrealDHT,'c*-');

grid;
axis tight;
legend('Built-In conv.m','fastconvDFT.m','fastconvrealDFT.m','fastconvrealDHT.m','Location','NorthWest');
title('Execution Time for Various fast convolution Implementations');
xlabel('log_2(length(x)),log_2(length(y))');
ylabel('Execution Time (sec)');



