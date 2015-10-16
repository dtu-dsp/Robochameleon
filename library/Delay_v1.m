%> @file Delay_v1.m
%> @brief Applies a time delay to a signal
%>
%> @class Delay_v1
%> @brief Applies a time delay to a signal
%>
%> Delays a signal_interface by the number of samples specified
%> first argument indicates the delay and second indicates weather it's
%> 'symbols' or 'samples'
%>
%> @author Miguel Iglesias Olmedo
%> @version 1
classdef Delay_v1 < unit
    
    properties
        nInputs=1;
        nOutputs=1;
        
        %> Delay to apply
        delay;
        %> apply delay to symbols or samples {'symbols' | 'samples'}
        mode='samples';
    end
    
    methods
        %> @brief Constructor
        %> 
        %> There are two ways of using this, "old" and "standard":
        %> parameters can either be passed as two arguments, or a single
        %> structure.
        %> 
        %> @code
        %> P = Delay_v1(100, 'symbols')
        %> P2 = Delay_v1(100)
        %> params = struct('delay', 100, 'mode', 'symbols');
        %> Q = Delay_v1(params);
        %> @endcode
        %> P and Q are equivalent. P2 is similar, but the delay is applied
        %> at the sample level rather than the symbol level.
        function obj = Delay_v1(varargin)
            if isstruct(varargin{1})
                setparams(obj, varargin{1}, {'delay'});
            else
                if nargin < 2
                    obj.mode = 'samples';
                else
                    obj.mode = varargin{2};
                end
                obj.delay = varargin{1};
            end
        end
        
        %> @brief Traverse function
        %>
        %> Time shift is applied circularly to the signal - be careful at
        %> edges.
        function out = traverse(obj,sig)
            shift = obj.delay;       
            if strcmp(obj.mode, 'symbols') || strcmp(obj.mode, 'bits')
                shift = sig.Nss*obj.delay;
            end
            out = sig.fun1(@(x) circshift(x, shift));
        end
    end
    
end

