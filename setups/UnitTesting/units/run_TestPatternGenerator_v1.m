clearvars -except testFiles nn
close all

%% Parameters
param.M                 = 16;        % Modulation order
%% Create object
ppg = PatternGenerator_v1(param);
%% Traverse
out = ppg.traverse();

EDGES = [-.5 .5 1.5];
zerosAndOnes = histc(out.getRaw(),EDGES);
fprintf('Number of columns = log2(M) = %d \n', log2(param.M))

for nn=1:log2(param.M)
    fprintf('Column #%d: \n Ones: %d - Zeros: %d \n',...
            nn,zerosAndOnes(1,nn),zerosAndOnes(2,nn))
end
