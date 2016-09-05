%> @file ClassTemplate_v1.m
%> @brief A short description of the file containing a class or function

%>@class ClassTemplate_v1
%>@brief A short description of the class
%>
%> @ingroup {base|stableDSP|physModels|roboUtils|coreDSP|utils|labTools}
%> 
%> This unit is based on the model described in \ref BookAuthor1 "[1, section 2]".
%> A longer description of the class, with all the details required which spans multiple lines
%> A longer description of the class, with all the details required which spans multiple lines
%> A longer description of the class, with all the details required which spans multiple lines
%>
%> __Observations__
%>
%> 1. First observation
%>
%> 2. Second observation
%>
%>
%> __Conventions__
%> * First convention
%> * Second convention
%>
%>
%> __Example__
%> @code
%>   % Here we put a FULLY WORKING example using the MINIMUM set of required parameters
%>   param.classtemp.param1      = 2;
%>
%>   clTemp = ClassTemplate_v1(param.classtemp);
%>
%>   param.sig.L = 10e6;
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 193.1e12;
%>   param.sig.Rs = 10e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   sIn = createDummySignal();
%>
%>   sigOut = clTemp.traverse(sIn);
%> @endcode
%>
%>
%> __Advanced Example (Optional)__
%> @code
%>   % Here we put a FULLY WORKING example using a more extended set of parametersedit 
%>   param.classtemp.param1      = 2;
%>   param.classtemp.param2      = 'test';
%>   param.classtemp.param3      = false;
%>
%>   clTemp = ClassTemplate_v1(param.classtemp);
%>
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 193.1e12;
%>   param.sig.Rs = 10e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = rand(1000,2);
%>   sIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = clTemp.traverse(sIn);
%> @endcode
%>
%> __References__
%>
%> * \anchor BookAuthor1 [1] First formatted reference
%> * \anchor BookAuthor2 [2] Second formatted reference
%>
%> @author Author 1
%> @author Author 2
%>
%> @version 1
classdef ClassTemplate_v1 < unit

    properties        
        %> Description of param1 [measurment unit]. (Don't say anything about default values, they go in the constructor)
        param1 = 5
        %> Description of param2 [measurment unit]. (Parameters should start in lower case).
        param2
        %> Description of param3Enabled which is a flag that can take values true or false. Append the Enabled suffix.
        param3Enabled
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;        
    end
    
    properties(GetAccess=public, SetAccess=protected)
        %> Internal variables that shuld not be set by the user
        myProp;
    end
    
    methods (Static)
        
    end
    
    methods

        %> @brief Class constructor
        %>
        %> Constructs an object of type ClassTemplate_v1 and more information..
        %> Don't put example here, since we have it in the description..
        %>        
        %> @param param.param1          Description of param1 (Start description sentence with capital letter) [unit]. [Default: Value]
        %> @param param.param2          Description of param2 (Start description sentence with capital letter) [unit].
        %> @param param.param3Enabled   Description of a flag to enable or disable something. [Default: Value]
        %> 
        %> @retval obj      An instance of the class ClassTemplate_v1
        function obj = ClassTemplate_v1(param)                                       
            % Automatically assign params to matching properties
            % All the parameters without a default value specified in the property definition
            % should be put in requiredParams
            requiredParams = {'param2'};
            obj.setparams(param, requiredParams);                
        end
        
        %> @brief Brief description of what the traverse function does
        %>
        %> @param in    The signal_interface of the input signal that...
        %> 
        %> @retval out  The signal_interface of the signal which has been...
        function out = traverse(obj, in)
            
        end
    end
end
