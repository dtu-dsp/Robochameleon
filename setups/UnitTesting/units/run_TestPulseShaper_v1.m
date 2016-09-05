clearvars -except testFiles nn
close all
%%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Check WavformGenerator_v1 to have this functionality in one module
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Parameters
param.M                 = 4;        % Modulation order
param.modulationFormat  = 'QAM';    % Modulation format
param.N                 = 2;        % Number of modes (not necessary)
param.samplesPerSymbol  = 16;       % Samples per symbol
param.pulseShape        = 'rrc';    % Pulse shape
param.rollOff           = 0.2;    % Rolloff factor

sg_param=paramDeepCopy('SymbolGenerator_v1',param);
ps_param=paramDeepCopy('PulseShaper_v1',param);

%% Create object
sg = SymbolGenerator_v1(sg_param);
ps = PulseShaper_v1(ps_param);

%% Traverse Object
out     = sg.traverse();
out2    = ps.traverse(out);

%%
pconst(out2)