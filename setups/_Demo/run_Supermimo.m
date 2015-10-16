% Run "SuperMIMO" example
%
% setup_Supermimo.m is a tutorial on syntax for multiple-input-multiple 
% modules.  This script (run_Supermimo) runs the setup.

%Initialize Matlab (add relevant folders to path)
robochameleon;

%Construct system
system = setup_Supermimo;

%Run simulation
traverse(system);