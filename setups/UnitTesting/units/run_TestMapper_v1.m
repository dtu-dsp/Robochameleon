clearvars -except testFiles nn
close all
%%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Check SymbolGenerator_v1 to have this functionality in one module
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Parameters
param.M                 = 4;        % Modulation order
param.modulationFormat  = 'QAM';    % Modulation format
param.N                 = 2;        % Number of modes (not necessary)

ppg_param=paramDeepCopy('PatternGenerator_v1',param);
mp_param=paramDeepCopy('Mapper_v1',param);

%% Create object
ppg = PatternGenerator_v1(ppg_param);
mp  = Mapper_v1(mp_param);

%% Create object
out     = ppg.traverse();
out2    = mp.traverse(out);

%%
figure(1)
plot(real(out2(:)),imag(out2(:)),'s')