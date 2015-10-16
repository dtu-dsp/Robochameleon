classdef MyModule_v1 < module
    
    properties
        nInputs = 2;
        nOutputs = 4;
    end
    
    methods
        function obj = MyModule_v1(param)
            % Units
            a = A(param.paramA);
            b = B(param.paramB);
            c = C(param.paramC);
            d = D(param.paramD);
            
            % Connections
            obj.connectInputs({a b},[1 1])
            a.connectOutputs(c,1);
            b.connectOutputs(c,2);
            c.connectOutputs({d obj.outputBuffer obj.outputBuffer},[1 3 4])
            d.connectOutputs({obj.outputBuffer obj.outputBuffer},[1 2]);
            
            obj.exportModule();
        end
    end
    
end