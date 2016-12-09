%> @file BERT_v1.m
%> @brief Contains the implementation of a BER counter
%>
%> @class BERT_v1
%> @brief Contains the implementation of a BER counter
%> 
%> @ingroup coreDSP
%>
%> Bit error rate tester. It outputs estimated and computed quality of
%> your signal in terms of Q factor, EVM, Pb, Ps, estimated number of
%> bit errors and symbol errors, as well as the computer BER and SER.
%> If PRBS pattern isn't passed as a parameter, the unit self-sets the
%> number of inputs to 2, so that the 2nd input is the PRBS coming out
%> the pattern generator.
%>
%> __Program Structure__
%>
%> The BERT executes the following functions in the followint order 
%> (from BERT_v1::traverse):
%>
%> -# Count errors and map their locations, using BERT_v1::bert
%> -# Calculate constellation quality metrics, from BERT_v1::bert, either 
%> BERT_v1::getQ or BERT_v1::getEVM is called (depending on constellation type), 
%> and the expected BER is calculated either in BERT_v1::bert (for ASK) or 
%> BERT_v1::BERfromQAMEVM (for QAM)
%> -# Choose which blocks to include/exclude in total BER, using
%>  BERT_v1::ProcessBER
%> -# Plot all results
%>
%> If speed is a concern, the second and fourth steps can be disabled using
%> object proprties EnableMetrics and draw, respectively. Also, FastMode
%> operation allows for only caluclate metrics and plots up to 10000 symbols
%> in the constellation.
%>
%> __Output Structure__
%>
%> The class results structure contains all calculated results.  It has two
%> levels of hierarchy:
%>
%> -# obj.results.<property> describes a property of the entire signal
%> -# obj.results.Col<N>.<property> describes a property the signal in column N
%> 
%> obj.results will always contain fields 'ber', 'ser', 'totalbits', and
%> 'totalsymbs' (bit error rate, symbol error rate, total bits counted, and
%> total symbols counted).   obj.results.Col<N> is a more flexible
%> structure type, whose fields may vary depending on the counting method,
%> post-processing method, modulation format, etc.
%>
%> If plotting (draw) is enabled, these will be both drawn in a figure and entered
%> into the log.  Otherwise, the user is responsible for extracting the
%> information of interest.
%>
%> @see error_counter_v7c.m
%> @see constref.m
%>
%> @author Miguel Iglesias Olmedo
%> @author 6.2015 Molly Piels
classdef BERT_v1 < unit
    
    properties
        nInputs = 1;
        nOutputs = 0;
        
        %> Constellation order
        M;
        %> Constellation type {'QAM' | 'ASK' | ... }
        ConstType;
        %> Full Constellation
        Constellation;
        %> Transmitted data
        TxData;
        %> Coding gray or binary  {'gray' | 'bin'}
        Coding;   
        %> Block length for error counting
        BlockLength;
        %> Which counter to use {'generic'}
        CounterMethod;
        %> Decision type {'hard' | 'soft'}
        DecisionType;
        %> Calculate EVM, Q, etc. {true | false}
        EnableMetrics; 
        %> Calculate BER, SER, errorgram etc
        EnableCounter; 
        %> How to identify bad blocks {'none' | 'threshold' | 'probability'}
        PostProcessMethod;
        %> Disables Counter and plots only 10000 symbols
        FastMode;
        %> Only calculate the signal columuns specified in this vector
        Only;
        %> (internal) Vector containing what columns to demodulate
        Cols;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Class constructor.  Required parameters are the constellation
        %> order (param.M) and type (param.ConstType, default QAM).  See
        %> the utils\constutils folder for correct syntax for constellation
        %> specification.
        %>
        %> Additional signal description parameters:
        %> - param.TxData \n
        %>      Transmitted data.  This should be a single cycle of the full transmitted 
        %>      binary PRBS sequence.  It can be either logical or double
        %>      with 1's and 0's.
        %> - param.Coding \n
        %>      Describes how the binary data is mapped to symbols.  The
        %>      options are with gray coding and binary (delay and add) coding.
        %>
        %> Computation-related parameters:
        %> - param.CounterMethod \n
        %>      Specify the counter to use.  This block is meant to hold a
        %>      number of counters.  See BERT_v1::bert for instructions on
        %>      how to format a counter to incorporate into the block.
        %> - param.BlockLength \n
        %>     Most counters segment the data into blocks of this length.
        %>     The post-processing algorithms require segmented data, so it
        %>     is important to specify this even if the counter used does not
        %>     require it.  
        %> - param.DecisionType \n
        %>     Many (but not all!) counters allow the user to choose
        %>     between hard and soft decision.  For hard decision, the
        %>     locations of constellation points are set to be the ideal
        %>     locations for that constellation.  For soft decision, they
        %>     are chosen by clustering the data using kmeans.
        %> - param.EnableMetrics \n
        %>     Enable calculating Q, EVM, and associated theoretical number
        %>     of symbol and bit errors.  Should be enabled generally,
        %>     but runtime improves if it is disabled, which can be useful
        %>     for parameter scans.
        %> - param.PostProcessMethod \n
        %>     After counting all errors in the entire sequence, only some
        %>     are considered when calculting the final BER and SER.  This
        %>     option allows the user to select this criteria.  The options
        %>     are 'probability', 'threshold', and default.  The default
        %>     option is to count all bits received.  If 'probability' is
        %>     selected, the BER is calculated for the whole sequence, and 
        %>     then blocks of symbols are included/excluded based on
        %>     whether or not the probability of that particular number of
        %>     errors given this average BER is above a certain threshold.
        %>     This probability is calculated assuming a binomial
        %>     distribution.  If 'threshold' is selected, all blocks with
        %>     BER above a certain threshold are rejected.  
        %>     All the associated thresholds are passed to the constructor
        %>     in the param.PostProcessMethod field, separated by the name
        %>     of the method by a space.  For example: @code
        %>     param.PostProcessMethod = 'threshold 0.1' @endcode will
        %>     result in all blocks with BER>0.1 being rejected.
        %> - param.FastMode \n
        %      Enabling this flag will only calculate the metrics and plot
        %      100k symbols.
        %> - param.draw \n
        %>     Enable or disable plotting (true results in the plot being
        %>     generated).
        %>
        %> Example:
        %> @code
        %> param.M=4;
        %> param.ConstType='ASK'
        %> param.TxData=gen_prbs(15);
        %> param.Coding = 'bin';
        %> param.DecisionType = 'hard';
        %> param.PostProcessMethod = 'probability 0.999';
        %> bert = BERT_v1(param);
        %> @endcode
        %>
        %> This will create a counter for 4PAM using hard-decision and
        %> assuming a delay-and-add mapping of bits to symbols.  Only blocks
        %> with block-wise BERs with a probability of 0.999 or higher will
        %> be considered when the BER for the whole sequence is calculated.
        %> The block length will be 2048 symbols, because this is the
        %> default.  Metrics will be calculated, and a plot will be
        %> generated, because this is also default behavior.
        %>
        %> @param param.M Constellation order
        %> @param param.ConstType Constellation type {'QAM' | 'ASK' | ...}
        %> @param param.TxData Transmitted data (binary sequence)
        %> @param param.Coding Coding gray or binary  {'gray' | 'bin'}
        %> @param param.CounterMethod Counting method {'generic'}
        %> @param param.BlockLength How many symbols to consider at once (any integer)
        %> @param param.DecisionType Hard vs. soft decision {'hard' | 'soft'}
        %> @param param.EnableMetrics Enable calculating Q, EVM, etc. {true | false}
        %> @param param.EnableCounter Enable calculating BER, SER, errorgram etc. 
        %> @param param.PostProcessMethod How to choose what blocks to count {'none' | 'threshold' | 'probability'}
        %> @param param.draw Turn plotting on/off {true | false}
        %>
        %> @retval obj Instance of the BERT_v1 class
        function obj = BERT_v1(param)
            %Intialize parameters
            obj.Constellation = paramdefault(param, {'Constellation'}, []);
            obj.ConstType = paramdefault(param, {'ConstType', 'const_type'}, 'QAM');
            if isempty(obj.Constellation)
                obj.M = param.M;
                obj.Constellation = constref(obj.ConstType,obj.M);
            else
                obj.M = length(obj.Constellation);
            end
            obj.Constellation = obj.Constellation./pwr.meanpwr(obj.Constellation);
            obj.TxData = paramdefault(param,{'prbs', 'data', 'TxData'},NaN);
            if isnan(obj.TxData)
                obj.nInputs=2;
                disp('BERT: Mode: 1st input data; 2nd input reference data');
            end
            obj.Coding = paramdefault(param, {'Coding', 'coding'}, 'bin');
            obj.BlockLength = paramdefault(param, {'BlockLength', 'blockLength'}, 2048);
            obj.CounterMethod = paramdefault(param,'CounterMethod','generic');
            obj.DecisionType = paramdefault(param, {'DecisionType', 'decision_type'}, 'soft');
            obj.EnableMetrics = paramdefault(param,'EnableMetrics',true);
            obj.EnableCounter = paramdefault(param,'EnableCounter',true);
            obj.PostProcessMethod = paramdefault(param, 'PostProcessMethod', 'none');
            obj.FastMode = paramdefault(param,{'FastMode','fast'},false);
            % Make sure we're doing something
            if ~(obj.EnableMetrics || obj.EnableCounter)
                obj.EnableMetrics = true;
            end
            if obj.FastMode
                obj.EnableMetrics = true;
                obj.EnableCounter = false;
            end
            obj.draw = paramdefault(param, 'draw', true);
            obj.Only =  paramdefault(param, {'Only','only'}, []);
        end
        
        %> @brief Main function
        %>
        %> Main function.  Performs basic signal conditioning, calls
        %> counter, post-processes, plots, then prints.  The BER, SER, and
        %> any other requested methods are saved in the object's results
        %> property.
        %>
        %> @param sig input signal
        %> @param refSig reference PRBS
        function traverse(obj, sig, refSig)
            % Obtain prbs
            if obj.nInputs==2
                obj.TxData = obj.obtainPRBS(refSig);
            end
            % Obtain input data
            if sig.Nss > 1
                decimator = Decimate_v1({});
                sig = decimator.traverse(sig);
            end
            % Do some checks
            if isempty(obj.ConstType)
                if isreal(sig.get())
                    obj.ConstType='ASK';
                else
                    obj.ConstType='QAM';
                end
            end
            if isempty(obj.Only)
                obj.Only = 1:sig.N;
            end
            % Count errors
            data = sig.getNormalized();
            obj.Cols = intersect(1:sig.N, obj.Only);
            for i=obj.Cols
                [obj.results.(['Col' num2str(i)]), ErrorMap(:,i)] = obj.bert(data(:,i));
            end
            if obj.EnableCounter
                obj.ProcessBER();
            end
            obj.printResults();
            if obj.draw
                for i=obj.Cols
                    obj.plot(data(:,i), ErrorMap, i)
                end
            end
        end
        
        %> @brief Error counter
        %>
        %> Error counter.  This part contains the main counting routines and
        %> calculates EVM, Q, etc.  
        %> 
        %> In order to be compatible with the rest of this unit, a counter
        %> must output the following parameters (some of these are 
        %>  redundant and could be calculated within the switch case): 
        %>
        %> -# BER per block (array)
        %> -# SER per block (array)
        %> -# Number of bit errors
        %> -# Number of symbol errors
        %> -# Number of bits counted
        %> -# Number of symbols counted
        %> -# Symbol error locations, or both mapped and received symbol
        %> sequences
        %>
        %> This last one is optional, but obj.EnableCalcMetrics should be
        %> disabled if error locations are not returned by the counter.  
        %> The remaining requirements are each mapped to a field of the output 
        %> results structure (res).  The results structure is quite flexible,
        %> and it is OK for a counter to return other values in it as well, but
        %> these will not be used elsewhere.  Results from this function
        %> are stored in obj.results.ColN, where N is an integer
        %> corresponding to the signal column.
        %>
        %> A compatible counter also must operate on an input signal that
        %> has been normalized to unity mean power and has to include a
        %> decision mechanism.  The object's built-in receiver (BERT_v1::rx) can
        %> be used to provide decisions.
        %>
        %> @param sig input signal
        %> @param refSig reference PRBS
        %> 
        %> @retval res.ber_block BER per block
        %> @retval res.ser_block SER per block
        %> @retval res.err_bits total bit errors
        %> @retval res.err_symb total symbol errors
        %> @retval res.totalbits total bits counted
        %> @retval res.totalsymb total symbols counted
        %> @retval res.Q Q factor
        %> @retval res.EVM Error vector magnitude (for QAM)
        %> @retval res.Ps Symbol error probability (for ASK)
        %> @retval res.Pb Bit error probability (for ASK)
        %> @retval res.est_bit_errors Estimated bit errors from Q, EVM, etc.
        %> @retval res.c cluster centers
        %> @retval res.boundaries decision boundaries (for ASK)
        %> @retval res.sig per-level standard deviations (for ASK)
        %> @retval ErrorMap logical array with 1's representing errors
        function [res, ErrorMap] = bert(obj, srx)
            %Shared counter parameters
            counterparams = struct('L', obj.BlockLength, 'M', obj.M, 'coding', obj.Coding, 'const_type', obj.ConstType, 'decision_type', obj.DecisionType);
            % Count errors
            if obj.EnableCounter
                switch obj.CounterMethod
                    case 'generic'
                        counterparams.ber_th = 0.45;        %set threshold high; we will deal with
                        [res.ber, res.ser,res.ber_block,res.ser_block,~,res.err_bits,res.totalbits,res.err_symb,res.totalsymb,ORIG_SYMBOLS, RX_SYMBOLS] =error_counter_v7c(srx,obj.TxData,counterparams);
                        ErrorMap = RX_SYMBOLS ~= ORIG_SYMBOLS;
                        ErrorMap = ErrorMap(obj.BlockLength:end).';
                    case 'miguel'
                        counterparams.ber_th = 0.45;        %set threshold high; we will deal with
                        [res.ber, res.ser,res.ber_block,res.ser_block,~,res.err_bits,res.totalbits,res.err_symb,res.totalsymb,ORIG_SYMBOLS, RX_SYMBOLS] =error_counter_miguel(srx,obj.TxData,counterparams);
                        ErrorMap = RX_SYMBOLS ~= ORIG_SYMBOLS;
                        ErrorMap = ErrorMap(:);
                    case 'xipa' % ONLY DELAY AND ADD
                        counterparams.ber_th = 0.45;        %set threshold high; we will deal with
                        [res.ber, res.err_bits, res.ser,  res.err_symb, res.totalbits, res.totalsymb, ORIG_SYMBOLS, RX_SYMBOLS,~] = BER_count_xipa_v2(counterparams,srx);
                        ErrorMap = RX_SYMBOLS ~= ORIG_SYMBOLS;
                        ErrorMap = ErrorMap(:);
                end
            end
            % Calculate metrics
            if obj.EnableMetrics
                % Get reference constellation
                if strcmp(obj.DecisionType, 'soft')
                    if obj.EnableCounter && exist('RX_SYMBOLS', 'var')
                        %We have already clustered and there is no reason to do
                        %this again
                        for ii=1:obj.M
                            idx = RX_SYMBOLS==ii;
                            c(ii)=mean(srx(idx));
                        end
                    else
                        [~, c] = sd_kmeans(srx,obj.Constellation);
                    end
                else
                    [c,P] = constref(obj.ConstType,obj.M);
                    c = c/sqrt(P);
                end
                res.c=c;
                
                % Calculate metrics
                switch obj.ConstType
                    case 'ASK'
                        [res.Q, res.boundaries, res.sig] = obj.getQ(obj.M, srx, RX_SYMBOLS, c);
                        res.Ps = 0.5*erfc(res.Q/sqrt(2));
                        res.est_sym_errors = round(res.Ps*length(srx));
                        
                        res.Pb = res.Ps/log2(obj.M);
                        res.est_bit_errors = round(res.Pb*length(srx)*log2(obj.M));
                    case 'QAM'
                        res.evm = obj.getEVM(srx,c(:));
                        res.Pb = obj.BERfromQAMEVM(res.evm, obj.M);
                        res.est_bit_errors = round(res.Pb*length(srx)*obj.M);
                        
                        res.Ps = res.Pb*obj.M;
                        res.est_sym_errors = round(res.Ps*length(srx));
                    otherwise
                        res.evm = nan;
                        res.Pb = nan;
                        res.est_bit_errors = nan;
                        
                        res.Ps = nan;
                        res.est_sym_errors = nan;
                end
            end
            

        end
        
        %> @brief Locates and returns the repeating sequence
        %>
        %> This can be used to find the PRBS in a sequence
        %>
        %> @param sig input signal (any)
        %> 
        %> @retval prbs extracted PRBS (logical)
        function prbs = obtainPRBS(obj,sig)
            if sig.N > 1
                warning('Taking only the first component as PRBS');
                data = sig.get;
                sig = sig.set(data(:,1));
            end
            if sig.Nss > 1
                decimator = Decimate_v1;
                sig = decimator.traverse(sig);
            end
            prbs = obj.rx(sig.getNormalized(), obj.M, obj.Coding);
            prbs = obj.trimPRBS(prbs);
            prbs = logical(prbs);
        end
        
        %> @brief Error post-processor
        %>
        %> This assesses which blocks or bits to consider when calculating the
        %> BER for the whole signal.  BER and SER are calculated for the
        %> whole signal and for each column individually.  Bit errors per
        %> block and block size are left unchanged.
        %>
        %> For the processing methods that include thresholds, the correct
        %> constructor syntax is
        %> @code
        %> param.PostProcessMethod = '<type> <value>'
        %> @endcode
        %> For 'threshold' type, blocks with BER > value are rejected.  For
        %> 'probability' type, blocks with probability < value are
        %> rejected.  The probability is calculated using the average BER
        %> for the whole sequence, or 100 errors for the whole sequence,
        %> whichever is greater.
        %> 
        %> @retval obj.results.ber BER for the whole signal
        %> @retval obj.results.ser SER for the whole signal
        %> @retval obj.results.ColN.ber BER for column N
        %> @retval obj.results.ColN.ser SER for column N
        %> @retval obj.results.ColN.badblocks map of rejected block locations
        function ProcessBER(obj)
            %parse input
            C=textscan(obj.PostProcessMethod, '%s %f');
            %initialize
            t_bits = 0;
            t_biterrors = 0;
            t_symb = 0;
            t_symberrors = 0;
            %main routines
            switch lower(cell2mat(C{1}))
                case('probability')
                    threshold = cell2mat(C(2));
                    robolog('Using probability-based BER processing with threshold %f', threshold);
                    for jj=obj.Cols
                        %Get average BER for sequence.  This is hard-coded to at minimum return 100
                        %errors for the whole trace.
                        BER_avg = max([100/sum(obj.results.(['Col' num2str(jj)]).totalbits), sum(obj.results.(['Col' num2str(jj)]).err_bits)/sum(obj.results.(['Col' num2str(jj)]).totalbits)]);
                        %calcuate the P(Ntest)|(BER = BER_avg)
                        Ntest=1:obj.results.(['Col' num2str(jj)]).totalbits(1);
                        P_err = betainc(1-BER_avg, Ntest(end)-Ntest, Ntest+1, 'upper');
                        err_th = log(1-threshold);
                        [~, idx]=min(abs(log(P_err)-err_th));
                        BER_max = Ntest(idx)/Ntest(end);
                        %determine good blocks and save
                        goodblocks = obj.results.(['Col' num2str(jj)]).err_bits./obj.results.(['Col' num2str(jj)]).totalbits<BER_max;
                        obj.results.(['Col' num2str(jj)]).badblocks = ~goodblocks;
                        
                        %calculate per column
                        obj.results.(['Col' num2str(jj)]).ber = sum(obj.results.(['Col' num2str(jj)]).err_bits(goodblocks))/sum(obj.results.(['Col' num2str(jj)]).totalbits(goodblocks));
                        obj.results.(['Col' num2str(jj)]).ser = sum(obj.results.(['Col' num2str(jj)]).err_symb(goodblocks))/sum(obj.results.(['Col' num2str(jj)]).totalsymb(goodblocks));
                        obj.results.(['Col' num2str(jj)]).comp_bit_errors=sum(obj.results.(['Col' num2str(jj)]).err_bits(goodblocks));
                        obj.results.(['Col' num2str(jj)]).comp_sym_errors=sum(obj.results.(['Col' num2str(jj)]).err_symb(goodblocks));
                        
                        %add totals
                        t_bits = t_bits + sum(obj.results.(['Col' num2str(jj)]).totalbits(goodblocks));
                        t_biterrors = t_biterrors + sum(obj.results.(['Col' num2str(jj)]).err_bits(goodblocks));
                        t_symb = t_symb + sum(obj.results.(['Col' num2str(jj)]).totalsymb(goodblocks));
                        t_symberrors = t_symberrors + sum(obj.results.(['Col' num2str(jj)]).err_symb(goodblocks));
                    end
                    
                case('threshold')
                    threshold = cell2mat(C(2));
                    robolog('Using threshold-based BER processing with threshold %f', threshold);
                    for jj=obj.Cols
                        %calculate per column
                        badblocks = obj.results.(['Col' num2str(jj)]).err_bits./obj.results.(['Col' num2str(jj)]).totalbits>=threshold;
                        obj.results.(['Col' num2str(jj)]).badblocks = badblocks;
                        obj.results.(['Col' num2str(jj)]).ber = sum(obj.results.(['Col' num2str(jj)]).err_bits(~badblocks))/sum(obj.results.(['Col' num2str(jj)]).totalbits(~badblocks));
                        obj.results.(['Col' num2str(jj)]).ser = sum(obj.results.(['Col' num2str(jj)]).err_symb(~badblocks))/sum(obj.results.(['Col' num2str(jj)]).totalsymb(~badblocks));
                        obj.results.(['Col' num2str(jj)]).comp_bit_errors=sum(obj.results.(['Col' num2str(jj)]).err_bits(~badblocks));
                        obj.results.(['Col' num2str(jj)]).comp_sym_errors=sum(obj.results.(['Col' num2str(jj)]).err_symb(~badblocks));
                        
                        %add totals
                        t_bits = t_bits + sum(obj.results.(['Col' num2str(jj)]).totalbits(~badblocks));
                        t_biterrors = t_biterrors + sum(obj.results.(['Col' num2str(jj)]).err_bits(~badblocks));
                        t_symb = t_symb + sum(obj.results.(['Col' num2str(jj)]).totalsymb(~badblocks));
                        t_symberrors = t_symberrors + sum(obj.results.(['Col' num2str(jj)]).err_symb(~badblocks)); 
                    end

                otherwise
                    robolog('Using standard (add all errors) BER processing');
                    t_bits = 0;
                    t_biterrors = 0;
                    t_symb = 0;
                    t_symberrors = 0;
                    for jj=obj.Cols
                        %add totals
                        t_bits = t_bits + sum(obj.results.(['Col' num2str(jj)]).totalbits);
                        t_biterrors = t_biterrors + sum(obj.results.(['Col' num2str(jj)]).err_bits);
                        t_symb = t_symb + sum(obj.results.(['Col' num2str(jj)]).totalsymb);
                        t_symberrors = t_symberrors + sum(obj.results.(['Col' num2str(jj)]).err_symb); 
                        %calculate per column
                        obj.results.(['Col' num2str(jj)]).ber = sum(obj.results.(['Col' num2str(jj)]).err_bits)/sum(obj.results.(['Col' num2str(jj)]).totalbits);
                        obj.results.(['Col' num2str(jj)]).ser = sum(obj.results.(['Col' num2str(jj)]).err_symb)/sum(obj.results.(['Col' num2str(jj)]).totalsymb);
                        obj.results.(['Col' num2str(jj)]).comp_bit_errors=sum(obj.results.(['Col' num2str(jj)]).err_bits);
                        obj.results.(['Col' num2str(jj)]).comp_sym_errors=sum(obj.results.(['Col' num2str(jj)]).err_symb);
                        obj.results.(['Col' num2str(jj)]).badblocks = 0;
                        
                    end
            end
            %calculate totals
            obj.results.ber = t_biterrors/t_bits;
            obj.results.totalbits = t_bits;
            obj.results.ser = t_symberrors/t_symb;
            obj.results.totalsymbs = t_symb;
            
        end
        
        %% Plotting functions
        %> @brief Main plotting function
        %>
        %> Main plotting function
        %>
        %> @param srx received data
        %> @param ErrorMap logical array showing error locations
        function plot(obj, srx, ErrorMap, i)
            flags = obj.initPlot(srx);
            rows = flags.size(1);
            cols = flags.size(2);
            if flags.hist
                subplot(rows,cols,flags.hist)
                obj.plotHistogram(srx, i)
            end
            if flags.constellation
                subplot(rows,cols,flags.constellation)
                if obj.FastMode % Just plot 1k symbols..
                    N=min(1e4,length(srx));
                    srx = srx((round(end/2)-floor(N/2)):(round(end/2)+floor(N/2)));
                end
                if isfield(obj.results.(['Col' num2str(i)]), 'c')
                    DSO_v1.plotConstellation(srx, obj.results.(['Col' num2str(i)]).c)
                else
                    DSO_v1.plotConstellation(srx)
                end
            end
            if flags.errorgram && obj.EnableCounter
                subplot(rows,cols,flags.errorgram)
                obj.plotErrors(ErrorMap(:,i),i)
            end
            if flags.table
                obj.plotResults(flags.table,obj.results.(['Col' num2str(i)]));
            end
        end
        
        %> @brief Initialize plot
        %>
        %> Generate plot figure and determine which quantities to plot
        %>
        %> @param srx received data
        function flags = initPlot(obj, srx)
            figure('Name','BERT analyzer')
            set(gcf, 'Units', 'pixels')
            if isreal(srx)
                ratioW = 0.3;
                ratioH = 0.8;
                flags.size = [3 1];
                flags.hist = 1;
                flags.constellation = 0;
                flags.errorgram = 2;
                flags.table = [0.1 0.25];
            else
                ratioW = 0.3;
                ratioH = 0.8;
                flags.size = [4 1];
                flags.hist = 0;
                flags.constellation = [1 2];
                flags.errorgram = 3;
                flags.table = [0.1 0.2];
            end
            scrsz = get(0,'ScreenSize');
            set(gcf,'OuterPosition',[1 scrsz(4)*(1-ratioH) scrsz(3)*ratioW scrsz(4)*ratioH ])
        end
        
        %> @brief Plot errorgram
        %>
        %> Plot error locations
        %>
        %> @param ErrorMap error locations
        %> @param i Column number
        function plotErrors(obj, ErrorMap, i)
            seq=zeros(size(ErrorMap));
            seq(ErrorMap)=1;
            errorgram = filter(ones(1,100),1,seq);
            errorgram = errorgram/max(errorgram);
            %     plot(errorgram, 'r')
            %     [N, C] = hist(histdata);
            %     hist(histdata)
            imagesc(errorgram');
            colormap(flipud(gray))
            %     hold on
            %     gridxy([crapSymbols length(seq)-crapSymbols], [])
            xlim([0 length(ErrorMap)])
            %title(['SER=' num2str(ser,'%.2e')]);
            res = obj.results.(['Col' num2str(i)]);
            set(gca,'YTick', [])
            if isfield(res, 'Q')
                xlabel(['Q = ' num2str(res.Q,'%.2f')])
            elseif isfield(res, 'EVM')
                xlabel(['EVM  : ' num2str(res.evm*100) ' %' ])
            end
            if isfield(res, 'badblocks')
                hold on
                ymax = max(get(gca, 'YLim'))*0.9;
                ymin = min(get(gca, 'YLim'))*1.1;
                for jj=1:length(res.badblocks)
                    if res.badblocks(jj)
                        curr_symb = sum(res.totalsymb(1:jj));
                        H=fill([curr_symb-res.totalsymb(jj)+1 curr_symb curr_symb curr_symb-res.totalsymb(jj)+1], [ymin, ymin ymax ymax], 'r');
                        set(H, 'FaceAlpha', 0.2);
                        set(H, 'EdgeColor', [1 0 0]);
                    end
                end
            end
        end
        
        %> @brief Histogram plotting function
        %>
        %> Histogram plotting function for PAM/ASK signals
        %>
        %> @param srx received data
        %> @param g received data
        %> @param c received data
        function plotHistogram(obj, srx, jj)
            colors
            [n, xout] = hist(srx,500);
            plot(n/sum(n), xout, '.', 'color', blue)
            xlim([0 max(n/sum(n))*1.5])
            ylim(1.1*[min(xout) max(xout)])
            hold on
            %plot metrics if we have calculated them
            if isfield(obj.results.(['Col' num2str(jj)]), 'c')
                sig = obj.results.(['Col' num2str(jj)]).sig;
                c = obj.results.(['Col' num2str(jj)]).c;
                boundary = obj.results.(['Col' num2str(jj)]).boundaries;
                for i=1:obj.M
                    gaussK = gaussmf(xout, [sig(i) c(i)]);
                    plot(gaussK/sum(gaussK)/obj.M,xout, 'color', red, 'LineWidth', linewidth);
                    text(max(n)/sum(n)*1.5, c(i),dec2bin(i-1, log2(obj.M)), 'fontsize', 15, 'color', red, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle')
                end
                gridxy([], boundary, 'LineStyle', '--', 'color', [1 1 1]/1.5)
            end
        end
        
        %> @brief Result plotting function
        %>
        %> Prints results into table in figure
        %>
        %> @param pos position
        %> @param res results to print
        function plotResults(obj, pos,res)
            cnames = {'SER','Sym err', 'BER', 'Bit err'};
            rnames = {'Estimated','Computed'};
            if obj.EnableMetrics
                data = [res.Ps res.est_sym_errors res.Pb res.est_bit_errors];
            end
            if obj.EnableCounter
                data(2,:) = [res.ser res.comp_sym_errors res.ber res.comp_bit_errors];
            end
            t = uitable('Parent',gcf,'Data',data,'ColumnName',cnames,...
                'RowName',rnames,'Units','normalized');
            size = get(t,'Extent');
            size(1:2) = pos;
            set(t,'Position', size);
            
        end
        
        %> @brief Result printing function
        %>
        %> Prints results into log (using robolog - this could end up
        %> either in the command window or a text file).
        %>
        %> @see robolog.m
        %>
        %> @param res results to print
        function printResults(obj)
            %get number of columns
            F=fieldnames(obj.results);
            N=numel(find(cell2mat(strfind(F, 'Col'))));
            fprintf('\r________________________ Error counter results ________________________\r ');
            if obj.EnableCounter
                report = 'Total results:\r';
                report = [report ' - ' num2str(obj.results.totalsymbs) ' symbols (' num2str(obj.results.totalbits) ' bits):\r'];
                report = [report sprintf(' - SER: %.2e\r', obj.results.ser)];
                report = [report sprintf(' - BER: %.2e\r', obj.results.ber)];
                robolog(report);
            end
            for jj=obj.Cols
                report = '';
                res = obj.results.(['Col' num2str(jj)]);
                report = [report 'Column ' num2str(jj) ':\r'];
                % Bad blocks
                if obj.EnableCounter && sum(res.badblocks) > 0
                    report = [report '   - Bad blocks: ' num2str(sum(res.badblocks)) ' out of ' num2str(length(res.badblocks)) '\r'];
                end
                % Metrics
                if isfield(res, 'Q')
                    report = [report '   - Q factor  : ' num2str(res.Q)];
                elseif isfield(res, 'evm')
                    report = [report '   - EVM  : ' num2str(res.evm*100) ' %%' ];
                end
                robolog(report);
                % Table
                t = PrintTable;
                t.HasRowHeader = true;
                t.HasHeader = true;
                t.addRow('   - ', 'SER', 'Sym err', 'BER', 'Bit err');
                if obj.EnableMetrics
                    t.addRow('Estimated', res.Ps,  res.est_sym_errors,  res.Pb,  res.est_bit_errors,  {'%.2e', '%d','%.2e', '%d' });
                end
                if obj.EnableCounter
                    t.addRow('Computed',  res.ser, res.comp_sym_errors, res.ber, res.comp_bit_errors, {'%.2e', '%d','%.2e', '%d' });
                end
                if ~getpref('roboLog', 'logToFile')
                    fprintf('\n');
                    t.display
                else
                    fid = fopen(getpref('roboLog', 'logFile'), 'a');
                    fprintf(fid, '\n');
                    t.print(fid);
                    fclose(fid);
                end
                disp(' ');
            end
        end
    end
    
    
    methods(Static)
        %> @brief Calculates PAM quality estimates
        %>
        %> Calculates PAM quality estimates
        %>
        %> @param M  Constellation order (M-PAM)
        %> @param srx: received symbols
        %> @param sdemod: demodulated symbols
        %> @param c: centroids
        %>
        %> @retval Q Q-factor
        %> @retval boundary decision boundaries
        %> @retval sig per level standard deviations
        function [Q, boundary, sig] = getQ(M, srx, sdemod, c)
            if min(sdemod) == 0
                sdemod=sdemod+1;
            end
            sig = zeros(M,1);
            boundary = zeros(M-1,1);
            Qi = zeros(M-1,1);
            for i=1:M
                sig(i) = std(srx(sdemod==i,:));
                if i>1
                    Qi(i) = abs(c(i)-c(i-1))/(sig(i)+sig(i-1));
                    boundary(i) = (c(i-1)+c(i))/2;
                end
            end
            boundary = boundary(2:end);
            Q = mean(Qi(2:end));
        end
        
        %> @brief Calculates EVM quality estimates
        %>
        %> Calculates EVM quality estimates
        %>
        %> @param srx: received symbols
        %> @param c: centroids
        %>
        %> @retval evm error vector magnitude
        function evm = getEVM(srx, c)
            for q=1:length(srx)
                for j=1:length(c)
                    ekc(j)=abs(srx(q,:) - c(j,:));
                end
                ek(q)=min(ekc.^2);
            end
            evm=sqrt(sum(ek)/length(srx));
        end
        
        %> @brief Calculates BER from EVM
        %>
        %> Calculates BER from EVM, using the formula from [1]
        %>
        %> __Warning__
        %>
        %> There is a misprint in [1] Eq. 4.  A @htmlonly &radic;2 @endhtmlonly 
        %> @latexonly $\sqrt{2}$ @endlatexonly factor must be removed, as
        %> pointed out by [2].
        %> 
        %> __References__
        %>
        %> [1] Schmogrow et al., "Error Vector Magnitude as a Performance Measure for Advanced
        %> Modulation Formats," Photononics Technology Letters, Vol. 24 No. 1, January
        %> 2012.
        %>
        %> [2] Schmogrow et al., "512 QAM Nyquist sinc-pulse transmission at 54 Gbit/s
        %> in an optical bandwidth of 3 GHz." Optics Express Vol. 20, No. 6, 12 March
        %> 2012.
        %>
        %> @param EVM  error vector magnitude
        %> @param M constellation order (M-QAM)
        %>
        %> @retval BER estimated BER
        %>
        %> @author Gerson Rodriguez de los Santos @htmlonly L&oacute;pez @endhtmlonly
        %> @latexonly L\'{o}pez @endlatexonly
        %> @date 20/11/2012
        %> 
        %> @author Miguel Iglesias Olmedo, where EVM is normalized
        %> with resect to the average power, instead of the peak power, removing the
        %> need of the k factor.
        %> @date 29/11/2014
        function BER = BERfromQAMEVM(EVM,M)
            
            L=ceil(sqrt(M));
            BER = ((1-1/L)/log2(L))*...
                erfc( sqrt( 3*log2(L)./( ((L^2)-1).*((EVM).^2)*log2(M) ) ) );
        end
        
        %> @brief Quick and dirty phase offset estimate
        %>
        %> Quick and dirty phase offset estimate
        %>
        %> @param srx  input data
        %> @param M constellation order (M-QAM)
        %>
        %> @retval phi estimated phase offset
        function phi = preEstimatePhase(srx, M)
            % Estimate initial constellation rotation
            rat=1.2; if (M==32 || M==8) rat=2/3; end % 32 is especial
            outter=max(srx(real(srx)>0 & imag(srx)>0 & abs(srx) < sqrt(2)*rat));
            [theta, rho] = cart2pol(real(outter),imag(outter));
            % Try to get the alphabet right
            phi = theta-pi/4;
        end
        
        %> @brief  Gets PRBS from signal
        %>
        %> Gets a signal and outputs a clean PRBS for comparison
        %>
        %> @param in  input data
        %>
        %> @retval out estimated PRBS
        function out = trimPRBS(in)
            corr = (diff(xcorr(in)));
            [~, index1] = max(corr);
            corr(index1)=0;
            [~, index2] = max(corr);
            prbsSize = abs(index1-index2);
            order = log2(prbsSize+1);
            if ~iswhole(order)
                robolog('Did not find a PRBS sequence, using complete reference', 'WRN')
                out = in;
            else
                robolog('PRBS size: 2^%d - 1\n', order)
                out = in(1:prbsSize);
            end
        end
        
       
        %> @brief  K-means based demodulation
        %>
        %> K-means based demodulation
        %>
        %> @param srx  input data
        %> @param M constellation order (M-QAM)
        %> @param Coding coding type {'bin', 'gray'}
        %>
        %> @retval out received symbols
        %> @retval c cluster centroids
        function [symbols, c] = rx(srx, M, Coding)
            % Normalize power
            srx = srx.'*modnorm(srx, 'avpow' ,1);
            srx = srx(:);
            % Define & initialize clusters
            if isreal(srx)
                c=getClusters(M,Coding,'linear',0);
            else
                c=getClusters(M,Coding,'qam',0);
            end
            [g, c] = kmeans(srx,M,'start',c,'emptyaction','singleton');
            symbols = g-1;
        end
        
        %> @brief   Skips symbols at beginning and/or end
        %>
        %> Skips symbols at beginning and/or end of sequence
        %>
        %> @param margin  how much of sequence to skip
        %> @param in input data
        %>
        %> @retval symbols estimated symbol sequence
        function out = skipMargin(margin, in)
            % If specified as percentage, convert to symbols
            if sum(margin) < 1
                skip = margin*length(in);
            else
                skip = margin;
            end
            if isscalar(skip)
                % Half and half
                skip = [skip/2 length(in)-skip/2];
            else
                % Up to this symbol
                skip(2) = length(in) - skip(2);
            end
            % If no margin...
            if skip(1) == 0
                skip(1) = 1;
            end
            if skip(2) > length(in)
                skip(2) = length(in);
            end
            % Trim
            out = in(round(skip(1)):round(skip(2)));
            out = out(:);
        end
        
    end
end