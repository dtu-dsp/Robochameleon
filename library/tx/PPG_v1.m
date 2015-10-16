%>@file PPG_v1.m
%>@brief PPG Pulse pattern generator class implementation.
%>
%>@class PPG_v1
%>@brief PPG Pulse pattern generator.
%>
%> Outputs a 2^order - 1 pseudorandom sequence repeated up to
%> total_length bits with Rs symbol rate. If block
%> attribute is set, the unit is set to do block-processing.
%>
%> _Example PRBS sequence generator polynomials_
%>
%> * PRBS7 = x^7 + x^6 + 1
%> * PRBS15 = x^15 + x^14 + 1
%> * PRBS23 = x^23 + x^18 + 1
%> * PRBS31 = x^31 + x^28 + 1
%>
%> @author Miguel Iglesias
%>
%> @version 1
classdef PPG_v1 < unit
    %PPG Pulse pattern generator.
    % Outputs a 2^order - 1 pseudorandom sequence repeated up to
    % total_length bits with Rs symbol rate and Fs sampling rate. If block
    % attribute is set, the unit is set to do block-processing.
    % @author Miguel Iglesias
    
    properties
        %> Number of inputs
        nInputs = 0;
        %> Number of outputs
        nOutputs = 1;
        %> PRBS order
        order = 15;
        %> Output sequence length
        total_length;
        %> Symbol rate
        Rs;
        %> Amplitude of high level
        level1 = 1;
        %> Amplitude of low level
        level0 = 0;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type PRBS
        %>
        %> @param param.nOutputs        Number of output sequences. [Default: 1].
        %> @param param.total_length    Output sequence lenghts [symbols].
        %> @param param.Rs              Symbol rate
        %> @param param.levels          Amplitude levels as vector [level0 level1]. Takes precedence respect
        %>                              level0/1
        %> @param param.level0          Amplitude of high level. [Default: 1].
        %> @param param.level1          Amplitude of low level. [Default: 0].        
        %>
        %> @retval obj      An instance of the class PPG_v1
        function obj = PPG_v1(param)
            if isfield(param, 'levels')
                param.level1=max(param.levels);
                param.level0=min(param.levels);
                param = rmfield(param,'levels');
            end
            obj.setparams(param)
        end
        
        %> @brief Set the amplitude levels of the PPG generator        
        %>
        %> @param levels        If scalar the value is assigned to level1. If vector the max is assigned to
        %>                      level1 and the min to level0.
        function setLevels(obj, levels)
            if length(levels) == 1
                obj.level1 =levels;
                obj.level0 =0;
            elseif length(levels) == 2
                obj.level1 = max(levels);
                obj.level0 = min(levels);
            else
                error('Error: Specify 2 values for the level of 1 and 0 please')
            end
        end
        
        function varargout = traverse(obj)
            % This outputs as many signal_interfaces as nOutputs.
            varargout = cell(1, obj.nOutputs);
            Poly = OrthogonalCodeGenerator_v1.PNgenpoly(obj.order);
            Poly = sort(obj.order-Poly, 'descend');     %for compatibility with gen_prbs
            InitState(Poly+1) = 1;
            for i=1:obj.nOutputs
                % Generate prbs
                %FASTER, but requires communication system toolbox
                try
                    prbs = comm.PNSequence('Polynomial',Poly,'InitialConditions', InitState(1:obj.order), ...
                        'SamplesPerFrame', obj.total_length);
                    data=step(prbs);
                    %re-set for next branch
                    InitState = data((i+5)*obj.order:(i+6)*obj.order);
                catch
                    prbs = gen_prbs(obj.order);
                    % Apply random delay to each prbs output
                    prbs = circshift(prbs,round(randn*(2^obj.order-1)));
                    % Make it long
                    N=ceil(obj.total_length/(2^obj.order-1));
                    data=repmat(prbs, N, 1);
                    data=+data(1:obj.total_length, :);
                end

                % Adjust levels
                data(data==1) = obj.level1;
                data(data==0) = obj.level0;
                % Obtain power
                P = sum(data.^2)/obj.total_length;
                power = pwr(inf, 10*log10(P*1e3));
                % Create signal interface object
                sig = signal_interface(data, struct('Rs', obj.Rs, 'Fs', obj.Rs, 'P', power, 'Fc', 0));
                varargout{i} = sig;
            end
        end
    end
end
