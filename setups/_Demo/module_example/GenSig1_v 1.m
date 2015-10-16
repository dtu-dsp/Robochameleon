classdef GenSig1_v1 < unit

    properties
        nInputs = 0;
        nOutputs = 1;
        Rs;
        Fs;
        Fc;
    end
    
    methods
        function obj = GenSig1_v1(param)
            obj.Rs = paramdefault(param,'Rs',10e9);
            obj.Fs = paramdefault(param,'Fs',40e9);
            obj.Fc = paramdefault(param,'Fc',const.c/1550e-9);
            
        end
        
        function sig_obj = traverse(obj)
            sig_param = struct('Rs',obj.Rs,'Fs',obj.Fs,'Fc',obj.Fc);
            sig_mat = randn(100,2); % 2-component random signal
            sig_obj = signal_interface(sig_mat,sig_param);
        end
    end
end