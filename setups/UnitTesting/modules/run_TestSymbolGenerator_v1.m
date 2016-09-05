clearvars -except testFiles nn
close all

%% Parameters
param.M                 = 4;        % Modulation order
param.modulationFormat  = 'QAM';    % Modulation format
% param.N                 = 2;        % Number of modes (not necessary)

%% Create object
sg = SymbolGenerator_v1(param);
param.M=16;
sg2 = SymbolGenerator_v1(param);

%% Create object
out = sg.traverse();
out2 = sg2.traverse();

%%
figure(1)
plot(real(out(:)),imag(out(:)),'s')
figure(2)
plot(real(out2(:)),imag(out2(:)),'s')