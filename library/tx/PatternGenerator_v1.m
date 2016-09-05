%>@file PatternGenerator_v1.m
%>@brief Pattern generator class implementation.
%>
%>@class PatternGenerator_v1
%>@brief Pattern generator class implementation.
%>
%> Outputs a random bit sequence with length "lengthSequence", using pseudorandom
%> bit sequences "PRBS" or Bernoulli distributed sequences "Random".
%>
%> __Observations__
%>
%> 1. If you define the Pattern type as PRBS, the sequence will be generated
%> according to the following polynomials:
%> * (Order=7)  = x^7 + x^6 + 1
%> * (Order=15) = x^15 + x^14 + 1
%> * (Order=23) = x^23 + x^18 + 1
%> * (Order=31) = x^31 + x^28 + 1
%>
%> 2. If you define the Pattern type as Random, the sequence will be
%> generated randomly using randi() function.
%>
%> __Example__
%>
%> @code
%>   % Here we put a FULLY WORKING example using the MINIMUM set of required parameters
%>   param.pg.M = 2;
%>   pg = PatternGenerator_v1(param.pg);
%>   sigOut = pg.traverse();
%> @endcode
%>
%> __Advanced Example__
%>
%> @code
%>   % Here we put a FULLY WORKING example using the MAXIMUM set of required parameters
%>   param.pg.M = 4;
%>   param.pg.typePattern = 'PRBS';
%>   param.pg.PRBSOrder = 31;
%>   param.pg.seed = [100 200]
%>   pg = PatternGenerator_v1(param.pg);
%>   sigOut = pg.traverse();
%> @endcode
%>
%> OR
%>
%> %> @code
%>   % Here ANOTHER FULLY WORKING example using the MAXIMUM set of required parameters
%>   param.pg.M = 4;
%>   param.pg.typePattern = 'Random';
%>   param.pg.probZero = 0.4;
%>   pg = PatternGenerator_v1(param.pg);
%>   sigOut = pg.traverse();
%> @endcode
%>
%> @author jcesardiniz
%> @version 2
classdef PatternGenerator_v1 < unit
    
    properties
        %> Number of inputs
        nInputs = 0;
        %> Number of outputs
        nOutputs = 1;
        %> PRBS order
        PRBSOrder = 15;
        %> Modulation Order
        M;
        %> Number of Modes (or polarizations)
        N = 1;
        %> Output sequence length
        lengthSequence = 10000;
        %> seeds for PRBS
        seed;
        %> Type of pattern
        typePattern = 'PRBS';
        %> Probability of zeros ('0')
        probZero = 0.5;
    end
    
    properties (Constant)
        allowedPRBSOrders = [7 15 23 31];
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type pattern generator
        %>
        %> @param param.lengthSequence   LengthSequence   - Output sequence lenghts [symbols].
        %> @param param.Rs          Rs          - Symbol rate
        %> @param param.typePattern TypePattern - Type of Pattern. Can be "PRBS" or "Random".
        %> @param param.PRBSOrder   PRBSOrder   - Polynomial order if typePattern set to "PRBS" (7, 15, 23, 31).
        %> @param param.seed        Seed        - Seeds for "PRBS" signal. Should be a vector. Cannot be zero.
        %> @param param.probZero    ProbZero    - Probability of zeros if typePattern set to "Random".
        %>
        %> @retval obj      An instance of the class PatternGenerator_v1
        function obj = PatternGenerator_v1(param)
            %> Setting parameters to object
            obj.setparams(param,{'M'},{'N','lengthSequence', 'PRBSOrder','seed','typePattern','probZero','allowedPRBSOrders'})
            
            if length(obj.M) ~= obj.N
                if length(obj.M) == 1
                    obj.M = obj.M*ones(1,obj.N);
                else
                    robolog('You shall define "M" with length equal to 1 or "N".', 'ERR')
                end
            end
            
            if strcmpi(obj.typePattern, 'prbs') && ~any(obj.PRBSOrder==obj.allowedPRBSOrders)
                robolog('PRBS order %d not allowed. The allowed PRBS orders are 7, 15, 23 and 31.', 'ERR', obj.PRBSOrder);
            elseif strcmpi(obj.typePattern, 'bernoulli')
                if ~isfield(param, 'probZero')
                    robolog('The probability of Zeros and Ones are set to default value 0.5', 'WRN')
                end
            end
            
            % this defines seeds to be used
            if ~isfield(param, 'seed')
                robolog('Seeds will be randomly generated.', 'NFO0')
                for ii = 1:sum(log2(obj.M))
                    obj.seed(ii) = randi(2^obj.PRBSOrder-1);
                end
                auxiliaryNumber = sort(obj.seed);
                auxiliaryNumber = auxiliaryNumber(2:end)-auxiliaryNumber(1:end-1);
                while sum(auxiliaryNumber == 0) > 0
                    for ii = 1:sum(log2(obj.M))
                        obj.seed(ii) = randi(2^obj.PRBSOrder-1);
                    end
                    auxiliaryNumber = sort(obj.seed);
                    auxiliaryNumber = auxiliaryNumber(2:end)-auxiliaryNumber(1:end-1);
                end
            else
                if length(obj.seed) < sum(log2(obj.M))
                    robolog('The remaining seeds will be randomly generated.', 'NFO0');
                    for ii = length(obj.seed)+1:sum(log2(obj.M))
                        obj.seed(ii) = randi(2^obj.PRBSOrder-1);
                    end
                    auxiliaryNumber = sort(obj.seed);
                    auxiliaryNumber = auxiliaryNumber(2:end)-auxiliaryNumber(1:end-1);
                    while sum(auxiliaryNumber == 0) > 0
                        for ii = length(obj.seed)+1:sum(log2(obj.M))
                            obj.seed(ii) = randi(2^obj.PRBSOrder-1);
                        end
                        auxiliaryNumber = sort(obj.seed);
                        auxiliaryNumber = auxiliaryNumber(2:end)-auxiliaryNumber(1:end-1);
                    end
                end
            end                        
        end
        
        function out = traverse(obj)
            if strcmp(obj.typePattern, 'PRBS')
                data = obj.gen_prbs_v1(obj.PRBSOrder, obj.seed, obj.lengthSequence); % Generate prbs
            else
                data = obj.gen_random_pattern_v1(obj.probZero, sum(log2(obj.M)), obj.lengthSequence);     % Generate Bernoulli Random data pattern
            end
            out = signal_interface(double(data), struct('Rs', 1, 'Fs', 1, 'P', pwr(inf, 10*log10(1)), 'Fc', 0)); % Create signal interface object
        end
    end
    
    methods (Static)
        function out = gen_prbs_v1(order, seed, lengthSequence)             % PRBS Generation
            switch order
                case 7
                    polynomial = [7 6];
                case 15
                    polynomial = [15 14];
                case 23
                    polynomial = [23 18];
                case 31
                    polynomial = [31 28];
            end
            out = zeros(lengthSequence, length(seed));
            for jj = 1:length(seed)
                out(1:order,jj) = de2bi(seed(jj), order)';
                for ii = (order+1):lengthSequence
                    out(ii,jj) = xor(out(ii-polynomial(1),jj),out(ii-polynomial(2),jj));
                end
            end
        end
        
        function out = gen_random_pattern_v1(probability,lines,lengthSequence)
            out = rand(lengthSequence, lines)>probability;
        end
    end
end
