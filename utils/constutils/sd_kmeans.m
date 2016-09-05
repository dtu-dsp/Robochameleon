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

s = warning('error','stats:kmeans:FailedToConverge'); % Change error to warning
try
    options = struct('MaxIter',15);
    [symb, centroids] = kmeans(X,numel(c),'onlinephase','off','options',options,'start',c,'emptyaction','singleton');
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

symb = uint16(symb(:));