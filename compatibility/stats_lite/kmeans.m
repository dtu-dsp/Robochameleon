%> @file kmeans.m 
%> @brief Substitute for matlab's kmeans algorithm from stats toolbox
%> 
%> Runs kmeans clustering algorithm in a way similar to matlab's version
%> 
%> __Syntax__
%> @code
%> idx = kmeans(X, k)
%> @endcode
%> Performs k-means clustering on the data matrix X assuming
%> k clusters.  The values in idx will be the cluster indices.  
%> @code
%> [idx, C] = kmeans(X, k)
%> @endcode
%> will also return C, the cluster centroids
%> @code
%> [idx, C] = kmeans(X, k, Name, Value, ...)
%> @endcode
%> will implement additional options as specified by the Name-Value pairs.
%> 
%>
%> __Name-value pair arguments__
%> * 'Start' - starting point of centroids
%> * 'MaxIter' - maximum number of iterations
%>
%> Other name-value pairs available in matlab's implementation are not
%> available in this version.  
%> 
%>
%> __Notes__
%> This file is a parameter parser only.  The algorithm is implemented in
%> kmeansSubstitute.m
%>
%> @see kmeansSubstitute.m
%> 
%> @author Molly Piels
%> @brief Substitute for matlab's kmeans algorithm from stats toolbox
function [varargout] = kmeans( varargin )



if nargin<2
    robolog('Not enough inputs', 'ERR');
end
%deal with first two arguments
X = varargin{1};
k = varargin{2};

%set up Matlab's input parser:
p = inputParser;
p.FunctionName = 'kmeans';
%parameters not used by k-means substitute:
p.addOptional('Display', 'off');
p.addOptional('Distance', 'cityblock');
p.addOptional('EmptyAction', 'singleton');
p.addOptional('OnlinePhase', 'off');
p.addOptional('Options', 0);
p.addOptional('Replicates', 1);
%parameters we want to use
if length(k) == 1
    p.addOptional('Start', 'sample');
else
    p.addOptional('Start', k);
end
p.addOptional('MaxIter', 100);

parse(p, varargin{2:end});

%initialize cluster centers if necessary
if ischar(p.Results.Start)
    switch p.Results.Start
        case 'sample'
            idx = randi(length(X), 1, k);
            start = X(idx);
        otherwise
            robolog('Specified starting method not implemented in lite version of kmeans', 'ERR');
    end
else
    start = p.Results.Start;
end


[g, c, sig2] = kmeansSubstitute(X(:), start(:), false, 0, p.Results.MaxIter);


%parse outputs
varargout{1} = g;
if nargout>1
    varargout{2} = c;
    if nargout>2
        varargout{3} = sig2*length(X);
        if nargout>3
            robolog('Pointwise distances not implemented in lite version of kmeans', 'ERR');
        end
    end
end

end

