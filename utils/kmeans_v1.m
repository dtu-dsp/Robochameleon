%> @file kmeans_v1.m
%> @brief k-means clustering algorithm for complex-valued data.
%>
%> This function is faster than matlab's built-in kmeans, but has worse performance
%> in finding the cluster centroids.
%>
%> __Example__
%> @code
%>   centers = kmeans_v1(initialCenters, DataPoints);
%>   centers = kmeans_v1(initialCenters, DataPoints, 'iterations', 50);
%>   centers = kmeans_v1(initialCenters, DataPoints, 'iterations', 50, 'tol', 1e-5);
%>   centers = kmeans_v1(initialCenters, DataPoints, 'iterations', 50, 'tol', 1e-5, 'gamma', 0.1);
%>%> @endcode
%>
%>
%> @author Edson Porto da Silva
%> @version 1

%> @brief This function applies the k-means algorithm to find the centers of complex-valued data clusters.
%>
%> @param initPosArray Initial particles positions (array of complex numbers)
%> @param symbVector Received constellation (array of symbols + noise, rotation, etc)
%> @param gamma Adaptation step. [Default: 0.5]
%> @param iterations Max number of allowed k-means interations. [Default: 10]
%> @param tol Convergence tolerance, i.e., if the average delta in
%>            the position the centers is lower than tol, the algorithm stops. [Default: 2e-3]
%>
%> @retval centers Clusters centroids.
function centers = kmeans_v1(initPosArray, symbVector, varargin)

% we want row vectors:
if size(initPosArray,2) == 1
    initPosArray = initPosArray.';
end

if size(symbVector,2) == 1
    symbVector = symbVector.';
end

% default values:
iterations = 10; % Max. number of iterations
tol = 2e-3;      % Convergence tolerance
gamma = 0.5;     % Adaptation step

% configure optional variables:
if nargin > 2
    for argidx = 1:2:nargin-2
        switch varargin{argidx}
            case 'gamma'
                gamma = varargin{argidx+1};
            case 'iterations'
                iterations = varargin{argidx+1};
            case 'tol'
                tol = varargin{argidx+1};
        end
    end
end

K_Centers = initPosArray;
deltaK    = initPosArray;
                                     
d = nan(length(K_Centers), length(symbVector)); % Alocate matrix of data-centers distance.

%% k-means
for n = 1:iterations
    
    for ii = 1:length(K_Centers) % Calculate distances from all datapoints to each center
         d(ii,:) = abs(K_Centers(ii)-symbVector);
    end
        [~, ind] = min(d);
        
    for ii = 1:length(K_Centers) 
        deltaK(ii)    = gamma*(K_Centers(ii)-mean(symbVector(ind == ii))); % Incremental position values of each center
        K_Centers(ii) = K_Centers(ii) - deltaK(ii);                        % Update center positions
    end
    
    if sum(abs(deltaK))/length(K_Centers) < tol % Convergence test (if average position increment is less than 2e-3, stop iterations)
        break;
    end
    
end
centers = K_Centers;
end
