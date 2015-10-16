%> @file PolMux_v1.m
%> @brief polmux emulation - delay, rotate polarization, add
%>
%> @class PolMux_v1
%> @brief polmux emulation - delay, rotate polarization, add
%> 
%>  @ingroup physModels
%>
%> Gets 2 signals and puts it into one with 2 colums. Syntax can be the same as
%> Delay_v1.m: 
%> P = PolMux_v1(N, 'mode') 
%> Default mode is 'samples', other options are 'symbols' and 'bits'
%> (equivalent)
%> Parameters can also be passed as a structure, with fields 'delay' and
%> 'mode'
%>
%> __Notes:__
%> Doesn't track the power. Use it only in digital domain, not in optical domain where
%> power requires to be tracked.
%>
%> Example:
%> @code
%> P = PolMux_v1(100, 'symbols')
%> params = struct('delay', 100, 'mode', 'symbols');
%> Q = PolMux_v1(params);
%> @endcode
%> Will build two equivalent pol-mux emulators with a delay of 100 symbols
%>
%> @author Miguel Iglesias Olmedo
%> @version 1
classdef PolMux_v1 < module
    properties
        nInputs = 1;
        nOutputs = 1;
    end
    
    methods
        %> @brief Class constructor
        function obj = PolMux_v1(varargin)
            obj.draw=true;
            splitter = BranchSignal_v1(2);
            if nargin>1
                delay = Delay_v1(varargin{1}, varargin{2});
            elseif isnumeric(varargin{1}) % number = delay
                delay = Delay_v1(varargin{1});
            else % params structure
                delay = Delay_v1(varargin{1});
                obj.draw=paramdefault(varargin{1}, 'draw', true);
            end
            comb = Combiner_v1('simple', 2);
            
            obj.connectInputs({splitter},1);
            splitter.connectOutputs({delay,comb},[1 1]);
            delay.connectOutputs(comb,2);
            comb.connectOutputs(obj.outputBuffer,1);
            obj.exportModule();
        end
    end
end

