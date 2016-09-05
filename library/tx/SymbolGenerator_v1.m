%>@file SymbolGenerator_v1.m
%>@brief Symbol generator class implementation.
%>
%>@class SymbolGenerator_v1
%>@brief Symbol generator.
%>
%> Outputs a symbol sequence of L
%>
%> __Example__
%> @code
%>      param.M                 = 4;
%>      param.modulationFormat  = 'QAM';
%>      sg      = SymbolGenerator_v1(param);
%>      sigOut  = sg.traverse();
%> @endcode
%>
%> @author Rasmus Jones
%>
%> @version 1
%>
%> @date February 2016
classdef SymbolGenerator_v1 < module
    
        properties
            %> Number of inputs
            nInputs = 0;
            %> Number of outputs
            nOutputs = 1;
        end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type SymbolGenerator_v1.
        %> It also constructs the PatternGenerator_v1 and the Mapper_v2
        %>        
        %> @param param.nInputs             Number of inputs
        %> @param param.nOutputs            Number of outputs
        %> @param param.modulationFormat    Modulation Format
        %> @param param.M                   Modulation order
        %> @param param.N                   Number of Modes (or polarizations)
        %> @param param.L                   Total length of sequence in symbols
        %> @param param.typePattern         Type of Pattern. Can be 'PRBS' or 'Random'.
        %> @param param.PRBSOrder           PRBS order               
        %> 
        %> @retval obj      An instance of the class SymbolGenerator_v1
        function obj = SymbolGenerator_v1(param)
            if isfield(param, 'nOutputs')
                obj.nOutputs = param.nOutputs;
            end
            ppg_param    =   paramDeepCopy('PatternGenerator_v1',param);
            mapper_param =   paramDeepCopy('Mapper_v1',param);
            
            ppg = PatternGenerator_v1(ppg_param);
            mapper = Mapper_v1(mapper_param);
            
            % Connect
            ppg.connectOutputs(repmat({mapper},[1 ppg.nOutputs]),1:ppg.nOutputs);
            mapper.connectOutputs(repmat({obj.outputBuffer},[1 obj.nOutputs]),1:obj.nOutputs);
            %% Module export
            exportModule(obj);
        end
    end
end