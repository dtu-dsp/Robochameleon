classdef setup_MySetup < module
    properties
        nInputs = 0;
        nOutputs = 0;
    end
    
    methods
        function obj = setup_MySetup(param)
            param.sig_param.nOutputs = 2;
            genSig = GenSigN_v1(param.sig_param);
            modules = MyModule_v1(param.modules);
            
            genSig.connectOutputs({modules modules},[1 2]);
            modules.connectOutputs({obj.outputBuffer obj.outputBuffer obj.outputBuffer obj.outputBuffer},1:4);
            
            obj.exportModule();
        end
        
    end
end