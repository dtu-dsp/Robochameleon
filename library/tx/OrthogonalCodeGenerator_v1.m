%> @file OrthogonalCodeGenerator_v1
%> @brief Contains the implementation of a binary/n-ary orthogonal code
%> generator
%>
%>
%> @class OrthogonalCodeGenerator_v1
%> @brief Orthogonal code generation
%>
%> This class can be used to output a binary/quaternary/etc. sequence in
%> the I-Q plane
%>
%> @author Molly Piels
%> @version 1
classdef OrthogonalCodeGenerator_v1 < unit
    
    properties
        % Internal variables
        nInputs=0;
        
        % Required attributes
        %> Number of outputs
        nOutputs;
        %> Code order - means different things for different types
        %> For exapmle PN outputs a 2^order-1 length PRBS
        order;
        %> Sequence length
        TotalLength;
        %> Symbol rate
        Rs;
        %> Code type {PN|Kasami|Gold}
        type;
        
    end
    
    methods
        function obj = OrthogonalCodeGenerator_v1(param)
            obj.order = paramdefault(param, 'order', 15);
            obj.TotalLength = paramdefault(param, 'TotalLength', 2^obj.order-1);
            obj.Rs = param.Rs;
            obj.nOutputs = paramdefault(param, 'nOutputs', 1);
            obj.type = paramdefault(param, 'type', 'PN');
            if isfield(param, 'levels')
                obj.level1=max(param.levels);
                obj.level0=min(param.levels);
                
            end
        end
        
        
        function varargout = traverse(obj)
            % This outputs as many signal_interfaces as nOutputs.
            varargout = cell(1, obj.nOutputs);
            
            Nseqs = obj.nOutputs;       %temporary...
            binblock = nan(obj.TotalLength, Nseqs);
            switch obj.type
                case 'PN'
                    Poly = obj.PNgenpoly(obj.order);
                    InitState(Poly+1) = 1;
                    prbs = comm.PNSequence('Polynomial',Poly,'InitialConditions', InitState(1:obj.order), ...
                        'SamplesPerFrame', obj.TotalLength);
                    binblock(:,1)=step(prbs);  
                    shift = round((2^obj.order-1)/Nseqs);
                    for jj=2:Nseqs
                        binblock(:,jj) = circshift(binblock(:,1), [shift 0]);
                    end
                    
                case 'Kasami'
                    Poly = obj.Kasamigenpoly(obj.order);
                    InitState(obj.order) = 1;
                    seq = comm.KasamiSequence('Polynomial', Poly, 'InitialConditions', InitState, ...
                        'SamplesPerFrame', obj.TotalLength, 'Index', -1);
                    for jj=1:Nseqs
                        binblock(:,jj)= step(seq);
                        release(seq);
                        seq.Index = seq.Index + 1;
                    end
                    
                case 'Gold'
                    [P1, P2] = obj.Goldgenpoly(obj.order);
                    InitState1(obj.order) = 1;
                    InitState2(P2+1) = 1;
                    seq = comm.GoldSequence('FirstPolynomial', P1, 'FirstInitialConditions', InitState1, ...
                        'SecondPolynomial', P2, 'SecondInitialConditions', InitState2(1:obj.order), ...
                        'Index', -2, 'SamplesPerFrame', obj.TotalLength);
                    for jj=1:Nseqs
                        binblock(:,jj)= step(seq);
                        release(seq);
                        seq.Index = seq.Index + 1;
                    end
                otherwise
                    error('Undefined code type')

            end
            
            %convert binary to BPSK
            if strcmp(obj.type, 'PN')||strcmp(obj.type, 'Kasami')||strcmp(obj.type, 'Gold')
                binblock = 2*(binblock-0.5);
            end
            
           
            power = pwr(inf, 1);
            for jj=1:obj.nOutputs
                sig = signal_interface(binblock(:,jj), struct('Fc', 0,'Rs', obj.Rs, 'Fs', obj.Rs, 'P', power));
                varargout{jj} = sig;
            end
        end
    end
    
    methods (Static)
        
        function [Pout]=PNgenpoly(Ntr)
            switch Ntr
                case 2
                    Pout = [2 1 0];
                case 3
                    Pout = [3 2 0];
                case 4
                    Pout = [4 3 0];
                case 5
                    Pout = [5 3 0];
                case 6
                    Pout = [6 5 0];
                case 7
                    Pout = [7 6 0];
                case 8
                    Pout = [8 6 5 4 0];
                case 9
                    Pout = [9 5 0];
                case 10
                    Pout = [10 7 0];
                case 11
                    Pout = [11 9 0];
                case 12
                    Pout = [12 11 8 6 0];
                case 13
                    Pout = [13 12 10 9 0];
                case 14
                    Pout = [14 13 8 4 0];
                case 15
                    Pout = [15 14 0];
                case 16
                    Pout = [16 15 13 4 0];
                case 17
                    Pout = [17 14 0];
                case 18
                    Pout = [18 11 0];
                case 19
                    Pout = [19 18 17 14 0];
                case 20
                    Pout = [20 17 0];
                case 21
                    Pout = [21 19 0];
                case 22
                    Pout = [22 21 0];
                case 23
                    Pout = [23 18 0];
                case 27
                    Pout = [27 26 25 22 0];
                case 31
                    Pout = [31 28 0];
                otherwise
                    error('No generator polynomial for this PN code order')
            end
        end
        
        function [Pout]=Kasamigenpoly(Ntr)
            if mod(Ntr, 2)
                error('Kasami sequence order must be even')
            end
            switch Ntr
                case 4
                    Pout = [4 1 0];
                case 6
                    Pout = [6 1 0];
                case 8
                    Pout = [8 4 3 2 0];
                case 10
                    Pout = [10 3 0];
                case 12
                    Pout = [12 6 4 1 0];
                    
                otherwise
                    error('No generator polynomial for this Kasami code order')
            end
        end
        
        function [Pout1, Pout2]=Goldgenpoly(Ntr)
            switch Ntr
                case 5
                    Pout1 = [5 2 0];
                    Pout2 = [5 4 3 2 0];
                case 6
                    Pout1 = [6 1 0];
                    Pout2 = [6 5 2 1 0];
                case 7
                    Pout1 = [7 3 0];
                    Pout2 = [7 3 2 1 0];
                case 9
                    Pout1 = [9 4 0];
                    Pout2 = [9 6 4 3 0];
                case 10
                    Pout1 = [10 3 0];
                    Pout2 = [10 8 3 2 0];
                case 11
                    Pout1 = [11 2 0];
                    Pout2 = [11 8 5 2 0];
                    
                otherwise
                    error('No generator polynomial for this Gold code order')
            end
        end
    end
    
end
