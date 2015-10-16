robochameleon

clear param
param.sig_param = struct('Rs',10e9,'Fs',40e9,'Fc',const.c/1550e-9);
param.modules = struct('paramA',[],'paramB',[],'paramC',[],'paramD',[]);
setup = setup_MySetup(param);
setup.traverse()
