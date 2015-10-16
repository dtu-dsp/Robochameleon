% This is a tutorial on syntax for multiple-input-multiple modules.  Two
% sources (so1 and so2) go to a 2x2 channel (ch), which is attached to two
% outputs (si1 and si2).  
%
% None of the modules do much:
%  The sources generate signal interfaces filled with a sequence of integers
%  The channel passes the inputs directly to the outputs
%  The outputs print the data in the command window.
%
% The script run_Supermimo.m runs this setup.
classdef setup_Supermimo < module
    
    properties (Hidden)
        nInputs = 0; % Number of input arguments
        nOutputs = 0; % Number of output arguments
    end
    
    methods
        function obj = setup_Supermimo
            %unit constructors
            si1 = TestSink_v1;
            si2 = TestSink_v1;
            ch = TestCh2x2_v1;
            so1 = TestSource_v1;
            so2 = TestSource_v1;
            
            %connections
            so1.connectOutputs(ch,1);
            so2.connectOutputs(ch,2);
            
            ch.connectOutputs({si1 si2},[1 1]);
            
            %module construction
            exportModule(obj);
        end
    end
    
    
    
end