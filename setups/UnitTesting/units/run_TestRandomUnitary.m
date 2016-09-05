%linear channel matrix generation test
%Calculate eigenvalue distribution for a set of matrices

N = 2;  %number of modes
Niter = 5e4;    %number of matrices to generate

%Generate matrices, calculate eigenvalues
lambdas = zeros(N, Niter);
for jj=1:Niter
    mat = LinChBulk_v1.random_unitary(N);
    lambdas(:,jj) = eig(mat);
end

%Calculate eigenvalue density
[rho, theta] = ksdensity((angle(lambdas(:))), linspace(-pi, pi, 100));
plot(theta, rho)
%should be evenly distributed in [-pi, pi]; ksdensity estimate will go to
%zero at the edges

%Check form for last matrix generated (is it symmetric, etc.)
%Rewrite in more familiar form (remove common phase so that a 2x2 matrix
%will have form [alpha, beta; -beta* alpha*];
commonphase = mean(angle(diag(mat)));
U=exp(-1i*commonphase)*mat;