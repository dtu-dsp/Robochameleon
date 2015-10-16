%>@file TxSymbolsGen_v1.m
%>@brief Implements symbol data generation for optical advanced
%>modulation formats
%> 
%>@class TxSymbolsGen_v1
%>@brief This class implements the mapping between PRBS sequences and
%> constellation symbols for polarization multiplexed coherent
%> transmission.
%>
%> Modulation Formats available:
%> 
%> * 1.PDM-QPSK.
%> * 2.PDM-16QAM.
%> * 3.PDM-64QAM.
%> * 4.Time Domain Hybrid QPSK\16QAM (Two options of multiplexing).
%> * 5.Polarization Domain Hybrid QPSK\16QAM.
%>
%> SymbolGenerator = TxSymbolsGen_v1(param)
%>
%> Set of parameters required to create:
%>@verbatim
%>  param.NumberOfSymbols;
%>  param.ModulationFormat;
%>  param.SymbolRate;
%>  param.PRBS_order;
%>  param.DataFolder;
%>  param.DataName;  
%>@endverbatim
%>
%> Traverse syntax : Eout = traverse(obj)
%>
%>@author Edson Porto da Silva
%>@version 2
classdef TxSymbolsGen_v1 < unit
    
    properties
        ModulationFormat;
        SymbolRate;
        NumberOfSymbols;
        PRBS_order;
        DataFolder;
        DataName;
        DataTx;
        Map;
        Demap;
        
        nOutputs = 1;
        nInputs = 0;
    end
    
    methods
        function obj = TxSymbolsGen_v1(param)          
            
            if mod(param.NumberOfSymbols,2) ~= 0
                error('Number of required symbols needs to be even.')
            end            
            obj.NumberOfSymbols  = param.NumberOfSymbols;
            obj.ModulationFormat = param.ModulationFormat;
            obj.SymbolRate       = param.SymbolRate;
            obj.PRBS_order       = param.PRBS_order;
            obj.DataFolder       = param.DataFolder;
            obj.DataName         = param.DataName;                     
        end
        
        function Eout = traverse(obj)
            
            if strcmp(obj.ModulationFormat, 'TD1_Hybrid_16QAM+QPSK')
                obj.ModulationFormat = 'TD_Hybrid_16QAM+QPSK';
                TypeMod = 'TD1';
            elseif strcmp(obj.ModulationFormat, 'TD2_Hybrid_16QAM+QPSK')
                obj.ModulationFormat = 'TD_Hybrid_16QAM+QPSK';
                TypeMod = 'TD2';
            end
            % Delay to be used in decorrelation of PRBS data:
            delay = 173; %
            rng('shuffle');
            
            % Pseudo random data generation:
            
            % Load saved PRBS data (to reduce processing time)
            load PRBS.mat;
            
            switch obj.PRBS_order
                case 15
                    Repetition = 2 + 5*floor(obj.NumberOfSymbols/length(PRBS15)); % Calculates the number of required PRBS repetitions to generate the symbols (min = 2)
                    PRBS = repmat(PRBS15, 1, Repetition);
                    warning('This code was not tested for PRBS15 use.')
                    warning('It is strongly recommended to use PRBS 23!')
                case 23
                    Repetition = 2 + floor(obj.NumberOfSymbols/length(PRBS23)); % Calculates the number of required PRBS repetitions to generate the symbols (min = 2)
                    PRBS = repmat(PRBS23, 1, Repetition);
                case 0
                    PRBS = randi([0 1], 1, 5*obj.NumberOfSymbols);
                otherwise
                    error('PRBS length not supported!')
            end
            
            
            switch obj.ModulationFormat
                case 'QPSK'
                    M = 4;
                    d1 = randi([0 100],1,1);
                    d2 = randi([101 200],1,1);
                    d3 = randi([201 300],1,1);
                    d4 = randi([301 400],1,1);
                    
                    % Bits Generation:
                    b1 = PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols);
                    b2 = PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols);
                    b3 = PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols);
                    b4 = PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols);
                    
                    BitsX = logical(reshape([b1; b2],obj.NumberOfSymbols*log2(M),1)); 
                    BitsY = logical(reshape([b3; b4],obj.NumberOfSymbols*log2(M),1)); 
                    
                    % Symbol mapping (binary to decimal):
                    Sx = bits2symb(BitsX,M);
                    Sy = bits2symb(BitsY,M);
                    
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding
                    
                    c_enc = c(obj.Map); % Encode constellation
                    S1 = c_enc(Sx).';   % Map symbols to constellation points
                    S2 = c_enc(Sy).';   % Map symbols to constellation points
                    
                    % Polarization 1
                    S1 = S1/mean(abs(S1));     % Normalization to Es = 1 (Symbol Energy)
                    
                    % Polarization 2
                    S2 = S2/mean(abs(S2));     % Normalization to Es = 1 (Symbol Energy)
                    
                    S = [S1; S2];              % Complex Dual-pol Symbols
                    obj.DataTx = [BitsX BitsY];
                    
                case '16QAM'
                    M = 16;
                    % Two polarization signal: DP-16QAM (1 Sample/symb)
                    d1 = randi([0 100],1,1);
                    d2 = randi([101 200],1,1);
                    d3 = randi([201 300],1,1);
                    d4 = randi([301 400],1,1);
                    d5 = randi([401 500],1,1);
                    d6 = randi([501 600],1,1);
                    d7 = randi([601 700],1,1);
                    d8 = randi([701 800],1,1);
                    
                    % Bits Generation:
                    b1 = PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols);
                    b2 = PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols);
                    b3 = PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols);
                    b4 = PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols);
                    b5 = PRBS(1+d5*delay:d5*delay+obj.NumberOfSymbols);
                    b6 = PRBS(1+d6*delay:d6*delay+obj.NumberOfSymbols);
                    b7 = PRBS(1+d7*delay:d7*delay+obj.NumberOfSymbols);
                    b8 = PRBS(1+d8*delay:d8*delay+obj.NumberOfSymbols);
                    
                    BitsX = logical(reshape([b1; b2; b3; b4],obj.NumberOfSymbols*log2(M),1)); 
                    BitsY = logical(reshape([b5; b6; b7; b8],obj.NumberOfSymbols*log2(M),1)); 
                    
                    Sx = bits2symb(BitsX,M);
                    Sy = bits2symb(BitsY,M);
                    
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding
                    
                    c_enc = c(obj.Map); % Encode constellation
                    S1 = c_enc(Sx).';   % Map symbols to constellation points
                    S2 = c_enc(Sy).';   % Map symbols to constellation points
                    
                    % Polarization 1
                    S1 = S1/mean(abs(S1));     % Normalization to Es = 1 (Symbol Energy)
                    
                    % Polarization 2
                    S2 = S2/mean(abs(S2));     % Normalization to Es = 1 (Symbol Energy)
                    
                    S = [S1; S2];              % Complex Dual-pol Symbols
                    obj.DataTx = [BitsX BitsY];
                    
                case 'TD_Hybrid_16QAM+QPSK'
                    
                    % QPSK symbols:          
                    
                    M = 4;
                    % Generate random PRBS delays:
                    d1 = randi([0 100],1,1);
                    d2 = randi([101 200],1,1);
                    d3 = randi([201 300],1,1);
                    d4 = randi([301 400],1,1);
                    
                    % Bits Generation:
                    b1 = PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols/2);
                    b2 = PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols/2);
                    b3 = PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols/2);
                    b4 = PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols/2);
                    
                    BitsX1 = logical(reshape([b1; b2],obj.NumberOfSymbols*log2(M)/2,1)); 
                    BitsY1 = logical(reshape([b3; b4],obj.NumberOfSymbols*log2(M)/2,1)); 
                    
                    clear b1 b2 b3 b4
                    % Symbol mapping (binary to decimal):
                    Sx = bits2symb(BitsX1,M);
                    Sy = bits2symb(BitsY1,M);
                    
                    [c, P] = constref('QAM',M);                      % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding:                    
                    c_enc = c(obj.Map);  % Encode constellation
                    S11 = c_enc(Sx).';   % Map symbols to constellation points
                    S11 = S11/mean(abs(S11));
                    S21 = c_enc(Sy).';   % Map symbols to constellation points
                    S21 = S21/mean(abs(S21));
                    
                    BitsX1 = logical(reshape(BitsX1,log2(M),obj.NumberOfSymbols/2)); 
                    BitsY1 = logical(reshape(BitsY1,log2(M),obj.NumberOfSymbols/2)); 
                    
                    clear Sx Sy b1 b2 b3 b4
                    
                    % 16QAM Symbols:                    
                    M = 16;
                    % Two polarization signal: DP-16QAM (1 Sample/symb)
                    d1 = randi([0 100],1,1);
                    d2 = randi([101 200],1,1);
                    d3 = randi([201 300],1,1);
                    d4 = randi([301 400],1,1);
                    d5 = randi([401 500],1,1);
                    d6 = randi([501 600],1,1);
                    d7 = randi([601 700],1,1);
                    d8 = randi([701 800],1,1);
                    
                    % Bits Generation:
                    b1 = PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols/2);
                    b2 = PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols/2);
                    b3 = PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols/2);
                    b4 = PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols/2);
                    b5 = PRBS(1+d5*delay:d5*delay+obj.NumberOfSymbols/2);
                    b6 = PRBS(1+d6*delay:d6*delay+obj.NumberOfSymbols/2);
                    b7 = PRBS(1+d7*delay:d7*delay+obj.NumberOfSymbols/2);
                    b8 = PRBS(1+d8*delay:d8*delay+obj.NumberOfSymbols/2);
                    
                    BitsX2 = logical(reshape([b1; b2; b3; b4],obj.NumberOfSymbols*log2(M)/2,1)); 
                    BitsY2 = logical(reshape([b5; b6; b7; b8],obj.NumberOfSymbols*log2(M)/2,1)); 
                    
                    clear b1 b2 b3 b4 b5 b6 b7 b8
                    
                    Sx = bits2symb(BitsX2,M);
                    Sy = bits2symb(BitsY2,M); 
                    
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding                    
                    c_enc = c(obj.Map);  % Encode constellation
                    S12 = c_enc(Sx).';   % Map symbols to constellation points
                    S12 = S12/mean(abs(S12));
                    S22 = c_enc(Sy).';   % Map symbols to constellation points    
                    S22 = S22/mean(abs(S22));
                    
                    BitsX2 = logical(reshape(BitsX2,log2(M),obj.NumberOfSymbols/2)); 
                    BitsY2 = logical(reshape(BitsY2,log2(M),obj.NumberOfSymbols/2));
                    
                    % Polarization 1
                    L = length(S12);
                    S1 = reshape([S11; S12],2*L,1).';
                    L = length(BitsX1);                    
                    BitsX = reshape([BitsX1; BitsX2],(2 + 4)*L,1).';
                    
                    % Polarization 2 
                    % Time Domain Aligned (TD1):
                    if strcmp(TypeMod,'TD1')
                        L = length(S21);
                        % Aligned QPSK/16QAM:                       
                        S2 = reshape([S21; S22],2*L,1).';
                        L = length(BitsY1);
                        BitsY = reshape([BitsY1; BitsY2],(2 + 4)*L,1).';
                    % Time Domain Alternated (TD2):
                    elseif strcmp(TypeMod,'TD2')
                        L = length(S21);
                        % Interleaved QPSK/16QAM:                       
                        S2 = reshape([S22; S21],2*L,1).';
                        L = length(BitsY1);
                        BitsY = reshape([BitsY2; BitsY1],(2 + 4)*L,1).';
                    else
                        error('\nIncorrect type specification of time domain hybrid modulation format.')
                    end                
             
                    S = [S1; S2];              % Complex Dual-pol Symbols               
                 
                    obj.DataTx = [BitsX BitsY];
                case 'PD_Hybrid_16QAM+QPSK'
                    % Generate QPSK Symbols
                    M = 4;
                    d1 = randi([0 100],1,1);
                    d2 = randi([101 200],1,1);
                    
                    % Bits Generation:
                    b1 = PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols);
                    b2 = PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols);
                    
                    BitsX = logical(reshape([b1; b2],obj.NumberOfSymbols*log2(M),1));                     
                    
                    % Symbol mapping (binary to decimal):
                    Sx = bits2symb(BitsX,M);
                      
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding                    
                    c_enc = c(obj.Map); % Encode constellation
                    S1 = c_enc(Sx).';   % Map symbols to constellation points
                    
                    % Polarization 1
                    S1 = S1/mean(abs(S1));     % Normalization to Es = 1 (Symbol Energy)
                    
                    % Generate 16QAM Symbols                    
                    M = 16;
                    % Two polarization signal: DP-16QAM (1 Sample/symb)
                    d1 = randi([0 100],1,1);
                    d2 = randi([101 200],1,1);
                    d3 = randi([201 300],1,1);
                    d4 = randi([301 400],1,1);
                    
                    % Bits Generation:
                    b1 = PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols);
                    b2 = PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols);
                    b3 = PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols);
                    b4 = PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols);
                    
                    BitsY = logical(reshape([b1; b2; b3; b4],obj.NumberOfSymbols*log2(M),1));                   
                    
                    Sy = bits2symb(BitsY,M);
                    
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding                    
                    c_enc = c(obj.Map); % Encode constellation
                    S2 = c_enc(Sy).';   % Map symbols to constellation points
                                       
                    % Polarization 2
                    S2 = S2/mean(abs(S2));     % Normalization to Es = 1 (Symbol Energy)
                              
                    S = [S1; S2];              % Complex Dual-pol Symbols     
                    
                    BitsX = [BitsX; logical(zeros(obj.NumberOfSymbols*log2(M)/2,1))];
                    obj.DataTx = [BitsX BitsY];
                    
                case '64QAM'
                    M = 64;
                    % Two polarization signal: DP-16QAM (1 Sample/symb)
                    d1  = randi([0 100],1,1);
                    d2  = randi([101 200],1,1);
                    d3  = randi([201 300],1,1);
                    d4  = randi([301 400],1,1);
                    d5  = randi([401 500],1,1);
                    d6  = randi([501 600],1,1);
                    d7  = randi([601 700],1,1);
                    d8  = randi([701 800],1,1);
                    d9  = randi([801 900],1,1);
                    d10 = randi([901 1000],1,1);
                    d11 = randi([1001 1100],1,1);
                    d12 = randi([1101 1200],1,1);
                    
                    % Bits Generation:
                    b1 =  PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols);
                    b2 =  PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols);
                    b3 =  PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols);
                    b4 =  PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols);
                    b5 =  PRBS(1+d5*delay:d5*delay+obj.NumberOfSymbols);
                    b6 =  PRBS(1+d6*delay:d6*delay+obj.NumberOfSymbols);
                    b7 =  PRBS(1+d7*delay:d7*delay+obj.NumberOfSymbols);
                    b8 =  PRBS(1+d8*delay:d8*delay+obj.NumberOfSymbols);
                    b9 =  PRBS(1+d9*delay:d9*delay+obj.NumberOfSymbols);
                    b10 = PRBS(1+d10*delay:d10*delay+obj.NumberOfSymbols);
                    b11 = PRBS(1+d11*delay:d11*delay+obj.NumberOfSymbols);
                    b12 = PRBS(1+d12*delay:d12*delay+obj.NumberOfSymbols);
                    
                    BitsX = logical(reshape([b1; b2; b3; b4;  b5;  b6 ],obj.NumberOfSymbols*log2(M),1)); 
                    BitsY = logical(reshape([b7; b8; b9; b10; b11; b12],obj.NumberOfSymbols*log2(M),1)); 
                    
                    clear b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12
                    
                    Sx = bits2symb(BitsX,M);
                    Sy = bits2symb(BitsY,M);
                    
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    [obj.Map, obj.Demap] = constmap('QAM',M,'gray'); % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding
                    
                    c_enc = c(obj.Map); % Encode constellation
                    S1 = c_enc(Sx).';   % Map symbols to constellation points
                    S2 = c_enc(Sy).';   % Map symbols to constellation points
                    
                    % Polarization 1
                    S1 = S1/mean(abs(S1));     % Normalization to Es = 1 (Symbol Energy)
                    
                    % Polarization 2
                    S2 = S2/mean(abs(S2));     % Normalization to Es = 1 (Symbol Energy)
                    
                    S = [S1; S2];              % Complex Dual-pol Symbols
                    obj.DataTx = [BitsX BitsY];                   
                case '32QAM'
                    M = 32;
                    % Two polarization signal: DP-16QAM (1 Sample/symb)
                    d1  = randi([0 100],1,1);
                    d2  = randi([101 200],1,1);
                    d3  = randi([201 300],1,1);
                    d4  = randi([301 400],1,1);
                    d5  = randi([401 500],1,1);
                    d6  = randi([501 600],1,1);
                    d7  = randi([601 700],1,1);
                    d8  = randi([701 800],1,1);
                    d9  = randi([801 900],1,1);
                    d10 = randi([901 1000],1,1);
                    
                    % Bits Generation:
                    b1 =  PRBS(1+d1*delay:d1*delay+obj.NumberOfSymbols);
                    b2 =  PRBS(1+d2*delay:d2*delay+obj.NumberOfSymbols);
                    b3 =  PRBS(1+d3*delay:d3*delay+obj.NumberOfSymbols);
                    b4 =  PRBS(1+d4*delay:d4*delay+obj.NumberOfSymbols);
                    b5 =  PRBS(1+d5*delay:d5*delay+obj.NumberOfSymbols);
                    b6 =  PRBS(1+d6*delay:d6*delay+obj.NumberOfSymbols);
                    b7 =  PRBS(1+d7*delay:d7*delay+obj.NumberOfSymbols);
                    b8 =  PRBS(1+d8*delay:d8*delay+obj.NumberOfSymbols);
                    b9 =  PRBS(1+d9*delay:d9*delay+obj.NumberOfSymbols);
                    b10 = PRBS(1+d10*delay:d10*delay+obj.NumberOfSymbols);
                    
                    BitsX = logical(reshape([b1; b2; b3; b4; b5 ],obj.NumberOfSymbols*log2(M),1)); 
                    BitsY = logical(reshape([b6; b7; b8; b9; b10],obj.NumberOfSymbols*log2(M),1)); 
                    
                    clear b1 b2 b3 b4 b5 b6 b7 b8 b9 b10
                    
                    Sx = bits2symb(BitsX,M);
                    Sy = bits2symb(BitsY,M);
                    
                    [c, P] = constref('QAM',M); % Generate reference constellation
                    obj.Map = [1:1:M]; % Create Gray constellation map/demap
                                                           
                    % Constellation map encoding
                    
                    c_enc = c(obj.Map); % Encode constellation
                    S1 = c_enc(Sx).';   % Map symbols to constellation points
                    S2 = c_enc(Sy).';   % Map symbols to constellation points
                    
                    % Polarization 1
                    S1 = S1/mean(abs(S1));     % Normalization to Es = 1 (Symbol Energy)
                    
                    % Polarization 2
                    S2 = S2/mean(abs(S2));     % Normalization to Es = 1 (Symbol Energy)
                    
                    S = [S1; S2];              % Complex Dual-pol Symbols
                    obj.DataTx = [BitsX BitsY];
                    
                case 'UserDefined'
                    Symbols = load([obj.DataFolder obj.DataName]);
                    S1 = Symbols.S1(1, 1:obj.NumberOfSymbols);           % Polarization 1
                    S1 = S1/mean(abs(S1));                               % Normalization to Es = 1 (Symbol Energy)
                    
                    S2 = Symbols.S2(1, 1:obj.NumberOfSymbols);           % Polarization 2
                    S2 = S2/mean(abs(S2));                               % Normalization to Es = 1 (Symbol Energy)
                    
                    S = [S1; S2];                                        % Complex Dual-pol Symbols
                    obj.DataTx = [Symbols.BitsS1' Symbols.BitsS2'];
                otherwise
                    error('\nModulation format is wrong defined or not supported.')
            end                        
       
            Eout = signal_interface(S.',struct('Fs',obj.SymbolRate,'Fc',0,'Rs',obj.SymbolRate,'P',pwr(Inf,0)));
        end
        
    end
    
    
    
end
