function [symb, centroids]= sd_kmeans(X,c)
% K-means soft decision digital demodulation
%
% SYMB = DD_KMEANS(X,C)
%
%   X - input constellation points
%   C - reference constellation
%   SYMB - demodulated symbols
%   centroids - Cluster centers
% Robert Borkowski, rbor@fotonik.dtu.dk
% Technical University of Denmark
% Modified by Miguel Iglesias Olmedo, miguelio@kth.se
% v3.0, 10 October 2015

if exist('kmeans','builtin')
    s = warning('error','stats:kmeans:FailedToConverge'); % Change error to warning
    try
        options = struct('MaxIter',15);
        [symb, centroids] = kmeans(X,c,'onlinephase','off','options',options,'start',c,'emptyaction','singleton');
    catch exception
        switch exception.identifier
            case 'stats:kmeans:FailedToConverge'
                %            warning('K-means did not converge. Using hard-decision.');
                symb = hd_euclid(X,c);
                centroids = c;
            otherwise
                rethrow(exception);
        end
    end
    warning(s); % Reenable error(?)
else
    [symb, centroids] = Kmeans(X,c);
end
symb = uint16(symb(:));

function [g c sig2] = Kmeans(data,k,varargin)
% Kmeans algorithm computes the center and variances
% for an input data
%   data: data to be processed
%   k: number of clusters
%   phi: initial phase
%   motion_plot: cool animation
%@author Miguel Iglesias Olmedo - miguelio@kth.se
% November, 2010

if nargin<4,
    motion_plot=false;
else
    motion_plot=varargin{2};
end
if nargin<3
    phi=0;
else
    phi=varargin{1};
end
if motion_plot
    blue=[78 101 148]/255;
    red=[216 41 0]/255;
    grey=[1 1 1]/2;
    green = [106, 168, 79]/255;
end

%% Preparing the data
m =  [real(data) imag(data)];
[maxRow, maxCol]=size(m);
c= [real(k) imag(k)];
k=length(c);
% Plot data
if motion_plot
    figure
    h = plot(real(data), imag(data), '.', 'color', blue);
    axis square
    ylabel('Quadrature')
    xlabel('In Phase')
    hold on
end

%% Starting algorithm
temp=zeros(maxRow,1);   % initialize as zero vector
num_it=1;
while 1,
    d=DistMatrix(m,c);  % calculate objcets-centroid distances
    [z,g]=min(d,[],2);  % find group matrix g
    if g==temp,
        break;          % stop the iteration
    else
        temp=g;         % copy group matrix to temporary variable
    end
    for i=1:k
        f=find(g==i);
        if f            % only compute centroid if f is not empty
            c(i,:)=mean(m(g==i,:),1);
            if motion_plot
                %%plot(c(:,1), c(:,2), '.', 'color', red, 'MarkerFaceColor', red/2)
            end
        end
    end
    num_it = num_it + 1;
end
% plot(c(:,1), c(:,2), 'o', 'color', red, 'MarkerFaceColor', red)
%% Ordering means
% [theta, rho] = cart2pol(c(:,1),c(:,2));
% limit = phase_1_sym - (2*pi/k)*0.1;       %Allows us to correct negative phase offset
% theta(theta<limit) = theta(theta<limit) + 2*pi;
% theta_ord = quicksort(theta);
% [tf, loc] = ismember(theta_ord,theta);
% rho_ord =rho(loc);
% [px,py] = pol2cart(theta_ord,rho_ord);
% c = [px, py];

%% Variance calculation
sig2 = zeros(k,1);
for i=1:k
    sig2(i) = mean(var(m(g==i,:)));
    if motion_plot
        res = 30;
        rad = sig2(i)^(1/4);
        plot(c(i,1)+rad*sin(2*pi*(0:res)/(res-1)),   c(i,2)+rad*cos(2*pi*(0:res)/(res-1)),'r');
        %text(c(i,1),c(i,2),int2str(i),'FontSize',18,'Color','k');
        if i==k
            p = (c(i,:) + c((1),:))/2;
        else
            p = (c(i,:) + c((i+1),:))/2;
        end
        mp = (p(2))/(p(1));
        b = p(2)-mp*p(1);
        x=0:0.001:1;
        if (p(1) < 0)
            x=-x;
        end
        %plot(x,mp*x+b, 'g')
    end
end
c = c(:,1) + 1i*c(:,2);
if motion_plot
    disp(' -> K means info:')
    disp(['   - Size of data : ' num2str(maxRow) ' samples in ' num2str(maxCol) 'D'])
    disp(['   - Num of Iter  : ' num2str(num_it) ])
end

function d=DistMatrix(A,B)
%%%%%%%%%%%%%%%%%%%%%%%%%
% DISTMATRIX return distance matrix between points in A=[x1 y1 ... w1] and in B=[x2 y2 ... w2]
% Copyright (c) 2005 by Kardi Teknomo,  http://people.revoledu.com/kardi/
%
% Numbers of rows (represent points) in A and B are not necessarily the same.
% It can be use for distance-in-a-slice (Spacing) or distance-between-slice (Headway),
%
% A and B must contain the same number of columns (represent variables of n dimensions),
% first column is the X coordinates, second column is the Y coordinates, and so on.
% The distance matrix is distance between points in A as rows
% and points in B as columns.
% example: Spacing= dist(A,A)
% Headway = dist(A,B), with hA ~= hB or hA=hB
%          A=[1 2 3; 4 5 6; 2 4 6; 1 2 3]; B=[4 5 1; 6 2 0]
%          dist(A,B)= [ 4.69   5.83;
%                       5.00   7.00;
%                       5.48   7.48;
%                       4.69   5.83]
%
%          dist(B,A)= [ 4.69   5.00     5.48    4.69;
%                       5.83   7.00     7.48    5.83]
%%%%%%%%%%%%%%%%%%%%%%%%%%%
[hA,wA]=size(A);
[hB,wB]=size(B);
if wA ~= wB,  error(' second dimension of A and B must be the same'); end
for k=1:wA
    C{k}= repmat(A(:,k),1,hB);
    D{k}= repmat(B(:,k),1,hA);
end
S=zeros(hA,hB);
for k=1:wA
    S=S+(C{k}-D{k}').^2;
end
d=sqrt(S);
