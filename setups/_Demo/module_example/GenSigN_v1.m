classdef GenSigN_v1 < unit

    properties
        nInputs = 0;
        nOutputs;
        Rs;
        Fs;
        Fc;
    end
    
    methods
        function obj = GenSigN_v1(param)
            obj.nOutputs = paramdefault(param,'nOutputs',1);
            obj.Rs = paramdefault(param,'Rs',10e9);
            obj.Fs = paramdefault(param,'Fs',40e9);
            obj.Fc = paramdefault(param,'Fc',const.c/1550e-9);
            
        end
        
        function varargout = traverse(obj)
            sig_param = struct('Rs',obj.Rs,'Fs',obj.Fs,'Fc',obj.Fc);
            varargout = cell(1,obj.nOutputs);
            for i=1:obj.nOutputs
                sig_mat = randn(100,2); % 2-component random signal
                varargout{i} = signal_interface(sig_mat,sig_param);
            end
        end
    end
end