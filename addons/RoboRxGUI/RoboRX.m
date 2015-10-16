classdef RoboRX < unit
    %ROBORX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nInputs=1;
        nOutputs=1;
        IP;
    end
    
    methods
        function obj = RoboRX(ip)
            obj.IP = ip;
        end
        function out = traverse(obj, in)
            out = in;
        end
        function reply = send(obj, command)
            reply = urlread(['http://' obj.IP '/arduino/' command]);
        end
        
    end
end

