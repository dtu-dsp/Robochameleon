%>@file signal_interface.m
%>@brief Signal interface class definition
%>
%>@class signal_interface
%>@brief Signal description class
%> 
%> @ingroup base
%>
%> signal_interface contains main signal attributes: waveform, carrier
%> frequency, sampling rate, symbol rate, and power.  Only objects of type
%> signal_interface can be passed between units.
%>
%> The waveform can contain multiple components/columns - the idea being that a
%> polarization multiplexed signal, e.g. could have 2 components/columns, one
%> for each state of polarization.  For multimode fiber, the definition
%> would be analogous, there would just be more columns.
%>
%> A number of operations are overwritten for signal_interface objects so
%> that they can be treated like arrays containing waveforms (e.g. sig1+sig2
%> produces a result that makes sense).  See methods for details.
%> 
%>
%> __Conventions__
%> * A signal_interface with Rs = 1 is analog
%> * A signal_interface with Fs = 1 is logical
%> * A signal_interface with Fc = 0 is electrical or logical
%>
%> __Power scaling__
%> Note that both the waveform and the object's power property contain
%> information about the waveform's amplitude.  Generally, when these
%> conflict, the information in the power property takes precedence.
%>
%> Power can be specified either as a per-column/mode quantity or for the whole
%> signal.  When these conflict, the per-column specification takes
%> precedence.
%>
%> On construction, if power is not specified, it is calculated
%> automatically from the waveform for each column separately.  If total
%> power but not per-column power is specified, the splitting fraction is
%> calculated numerically from the waveform.
%> @see pwr, getPColFromNumeric_v1
%>
%> __Example__
%> @code
%> s1= rand(10,1);
%> sigparams.Fs = 10e9;
%> sigparams.Fc = 0;
%> sigparams.Rs = 1e9;
%> sigparams.P = pwr(20, 3);
%> signal1 = signal_interface(s1,sigparams)
%> @endcode
%> will create a signal with random values, sampling rate 10G, no carrier
%> frequency, symbol rate (nominal) 1G, and 3dBm power and 20 dB SNR
%> (nominal).  See also run_TestSignalInterface.m, run_TestSignalInterfaceAdvanced.m
%>
%> @author Robert Borkowski
%> @version 2
classdef signal_interface
    properties (SetAccess=protected) % Read-only (can be changed only by a method)
        %> Carrier frequency (Hz)
        Fc = 0;
        %> Sampling rate (S/sec)
        Fs;
        %> Symbol rate (Baud)
        Rs; % Symbol rate
        %> Total signal power (pwr object)
        P; % Power
        %> Signal power per column (array of pwr objects)
        PCol; % Power per column in signal field
    end

    properties (SetAccess=protected,Hidden=true)
        %> Complex baseband LxN (L = length, N = number of components)
        E;
    end

    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type signal_interface.  Example:
        %> @code
        %> signal1 = signal_interface(s1,param)
        %> @endcode
        %> s1 is the waveform.  Each column corresponds to a signal
        %> component - i.e. a polarization multiplexed signal would be an
        %> Lx2 array
        %> param is the signal parameters.  For Fc, Fs, and Rs, there is a
        %> direct mapping to signal properties.  Power can be specified
        %> either as total signal power or power per column (this will take
        %> precedence if both are specified).
        %> In case power is not specified, a warning will be displayed, and
        %> the total signal power will be calculated from the waveform.
        function obj = signal_interface(signal,param)
            if isfield(param,'Fc') && isscalar(param.Fc), obj.Fc = param.Fc; else obj.Fc = 1; end
            if isfield(param,'Fs') && isscalar(param.Fs), obj.Fs = param.Fs; else robolog('Sampling frequency must be specified','ERR'); end
            if isfield(param,'Rs') && isscalar(param.Rs), obj.Rs = param.Rs; else obj.Rs = 1; end
            if isvector(signal)
                signal = signal(:);
            end
            obj.E = signal;
            if isfield(param, 'PCol')
                if ~isa(param.PCol,'pwr')
                    robolog('Power needs to be specified as object of "pwr" class.','ERR');
                else
                    if numel(param.PCol) ~= size(obj.E, 2)
                        robolog('The number of "pwr" objects in PCol must match the number of columns of the signal.', 'ERR');
                    end
                    obj.PCol = param.PCol;
                    obj.P = setPtot(obj);
                end
            elseif isfield(param,'P')
                if ~isa(param.P,'pwr')
                    robolog('Power needs to be specified as object of "pwr" class.','ERR');
                end
                if length(param.P) > 1
                    robolog('Power cannot be an array of "pwr" object. Use PCol instead.','ERR');
                end
                obj.P = param.P;
                avpow = pwr.meanpwr(signal);
                pwrfraction = avpow/sum(avpow);
                obj.PCol = repmat(obj.P, obj.N, 1).*pwrfraction;
            else
                robolog('Calculating power automatically - may be wrong', 'NFO0');
                robolog('  Set power using pwr object constructor:', 'NFO0');
                robolog('    signal = signal_interface(waveform, struct(''P'', pwr(SNR, Ptot), ...);', 'NFO0');
                robolog('  where SNR is in dB and Ptot is in dBm', 'NFO0');
                robolog('  See signal_interface and pwr documentation for more options', 'NFO0');
                avpow = pwr.meanpwr(signal);
                obj.PCol = pwr(inf, {avpow(1),'W'});
                for jj=2:obj.N
                    obj.PCol(jj) = pwr(inf, {avpow(jj),'W'});
                end
                obj.P = setPtot(obj);
            end
            %Check that user is not specifying properties that do not exist
            f = fieldnames(param);
            props = {'Fc', 'Fs', 'Rs', 'PCol', 'P'};
            [~,ai,~] = intersect(f,props);
            ai2 = false(size(f)); ai2(ai)=true; ai2=~ai2;
            if any(ai2), robolog('Following properties: %s are not used by signal_interface.', 'WRN', strjoin(strcat('''',f(ai2),''''),', ')); end


        end

        %> @brief Apply a function to each signal component separately
        %>
        %> This allows the user to avoid for loops and/or repmat if the same 
        %> operation is being performed on all modes independently.
        %>
        %> It should run faster than an implementation based on for
        %> loops/repmat, occupy fewer lines of code, and take less memory.
        %> It also automatically tracks changes in power, which can be
        %> useful for, e.g. filtering operations.
        %>
        %> __Examples__
        %> @code
        %> % apply a frequency shift
        %> t = genTimeAxisSig(input);
        %> frequency = 100e6;
        %>
        %> shiftedSignal = fun1(signal, @(x)x.*exp(1i*2*pi*frequency*t));
        %> @endcode
        %>
        %> Or for more complicated functions where top-down programming is required:
        %> @code
        %> 
        %> function out = traverse(obj, in)
        %> 
        %> out = fun1(in, @(x)obj.complicatedMethod(x));
        %>
        %> end
        %> 
        %> function Eout = complicatedMethod(obj, Ein)
        %> 
        %> %Here we put some code that acts on column vectors:
        %> Eout = Ein.*conj(Ein);
        %> Eout = filter(Eout, obj.B, obj.A);
        %> %etc
        %>
        %> end
        %>
        %> @endcode
        %>
        %> See also Matlab's bsxfun and arrayfun for examples
        function obj = fun1(obj,fun)
            obj.enforceLhs(nargout);
            s = cellfun(fun,mat2cell(get(obj),obj.L,ones(1,obj.N)),'UniformOutput',false);
            if ~all(cellfun(@(c)isequal(size(c),size(s{1})),s))
                robolog('Outputs after fun1 have different lengths. Cannot concatenate.','ERR');
            end
            obj.E = cell2mat(s);
            % Compute new power.
            % WARNING: SNR is not updated
            Pout = pwr.meanpwr(obj.getRaw);
            for i=1:length(obj.PCol)
                PCol_new(i) = pwr(obj.PCol(i).SNR, {Pout(i), 'W'});
            end
            obj.PCol = PCol_new;
            obj.P = setPtot(obj);
        end

        %> @brief Returns signal parameters in a struct
        %>
        %> This allows easily use and manipulate the parameters to construct a signal_interface
        %> derived from the existing one.
        %>
        %> @retval p Structure containing the signal necessary parameters
        function p = params(obj)
            p = struct( ...
                'Fs', obj.Fs, ...
                'Rs', obj.Rs, ...
                'Fc', obj.Fc, ...
                'P', obj.P, ...
                'PCol', obj.PCol ...
            );
        end
        
        %> @brief Retrieve the length of the signal
        function L = L(obj)
            L = size(obj.E,1);
        end
        
        %> @brief Retrieve the number of signal components
        function N = N(obj)
            N = size(obj.E,2);
        end
        
        %> @brief Jones matrix multiplication (overloads * operator)
        function obj = mtimes(obj,M)
            if ~isequal(size(M),([obj.N obj.N]))
                robolog('Jones matrix must be a NxN square matrix.','ERR');
            end

            Fnew=zeros(size(get(obj)));
            Pscale=zeros(obj.N, 1);
            for i=1:obj.N
                Fnew(:,i) = get(obj)*M(i,:).';
                Pscale(i) = norm(M(:,i), 2)^2;
            end
            obj.E = Fnew;
            %power scaling
            obj.PCol = obj.PCol.*Pscale;
            obj.P = setPtot(obj);
        end

        %> @brief Retrieve the number of samples per symbol
        function Nss = Nss(obj)
            % Oversampling rate of the signal
            Nss = obj.Fs/obj.Rs;
        end

        %> @brief Retrieve the sample period
        function Ts = Ts(obj)
            % Sampling time of the signal
            Ts = 1/obj.Fs;
        end

        %> @brief Retrieve the symbol period
        function Tb = Tb(obj)
            % Symbol time of the signal
            Tb = 1/obj.Rs;
            robolog('Don''t use Tb for symbol time. Use 1/Rs. This function will be soon removed','WRN');
        end

        %> @brief Set total power from power per column
        function Pout = setPtot(obj)
            Pout = obj.PCol(1);
            for jj=2:numel(obj.PCol)
                Pout = Pout + obj.PCol(jj);
            end
        end

        %> @brief Overload indexing access for read the field
        %>
        %> Allows to access the internal field with the the standard MATLAB indexing system.
        %>
        %> __Example__
        %> @code
        %> s1= rand(10,2);
        %> signal1 = signal_interface(s1,struct('Fs',10e9,'Fc',0,'Rs',1e9,'P',pwr(20,3)))
        %> signal1(1:10,1)
        %> @endcode
        %>
        %> If sig is a signal_interface you can access the field as sig(:,1)
        function sref = subsref(obj,s)
            switch s(1).type
                case '.'
                    sref = builtin('subsref',obj,s);
                case '()'
                    % If length(obj) > 1 obj is a vector fo signal_interface and the builtin method should be
                    % called
                    % length(s) <= 2 seems unuseful. Can be removed?
                    if length(s) <= 2 && length(obj) == 1
                        EScaled = obj.get;
                        sref = builtin('subsref',EScaled,s);
                        return
                    else
                        sref = builtin('subsref',obj,s);
                    end
                case '{}'
                    error('MYDataClass:subsref',...
                      'Not a supported subscripted reference')
            end
        end

        %> @brief Retrieve the signal
        function s = get(obj)
            s = getScaled(obj);
        end

        %> @brief Retrieve raw waveform.  Use with caution.
        function s = getRaw(obj)
            s = obj.E;
        end

        %> @brief Retrieve the signal with appropriate power scaling
        %>
        %> Retrieve the signal with appropriate power scaling.  Scaling is
        %> applied based on the per-column signal power
        function s = getScaled(obj)
            % Modified by Robert to include power scaling (28.08.2014).
            s = obj.E;
            Pin = pwr.meanpwr(s);
            for jj=1:obj.N
                Pout(jj) = obj.PCol(jj).Ptot('W');
            end
            if Pin ~=0
                s = bsxfun(@times, s, sqrt(Pout./Pin));
            else
                s = s;
                if Pout>0;
                    robolog('Cannot scale waveform with 0 power to %.2e W','WRN', Pout)
                end
            end
        end

        %> @brief Retrieve the signal normalized to unity power
        %>
        %> Normalize then return signal
        function s = getNormalized(obj)
            snorm = obj.normalize();
            s = snorm.E;
        end

        %> @brief Normalize stored signal to unity mean power
        %>
        %> Normalize the stored signal to unity power.  Normalization is
        %> based on the total signal power (same scaling is applied to all
        %> signal components)
        %> Since we mostly use this for DSP, stored power is changed to
        %> track new value so that get returns desired, normalized field.
        function sigout=normalize(obj)
            s = obj.E;
            s = s/sqrt(mean(pwr.meanpwr(s)));
            sigout = set(obj, s);
        end

        %> @brief Add two signals (coherently)
        function obj = plus(obj1,obj2)
            %check inputs
            param = struct('Fs',obj1.Fs);
            N = obj1.N;
            L = obj1.L;
            if param.Fs~=obj2.Fs || N~=obj2.N || L~=obj2.L
                robolog('Sampling rate, and signal sizes of both signals must be equal.','ERR');
            end
            param.Rs = obj1.Rs;
            if param.Rs~=obj2.Rs
                robolog('Assuming symbol rate of the first signal (%sBd).', 'WRN', formatPrefixSI(param.Rs,'%1.1f'));
            end
            param.PCol = obj1.PCol+obj2.PCol;
            Fc1 = obj1.Fc;
            Fc2 = obj2.Fc;
            param.Fc = (Fc1+Fc2)/2;
            s1 = bsxfun(@times,getScaled(obj1),exp(2j*pi*(Fc1-param.Fc)/param.Fs*(0:L-1)'));
            s2 = bsxfun(@times,getScaled(obj2),exp(2j*pi*(Fc2-param.Fc)/param.Fs*(0:L-1)'));
            s = s1+s2;
            obj = signal_interface(s,param);
            obj.P = setPtot(obj);
        end

        %> @brief Truncate signal length
        function obj = truncate(obj, L)
            obj.enforceLhs(nargout);
            sig = get(obj);
            obj = set(obj, sig(1:L, :));
        end

        %> @brief Combine multiple signals
        %>
        %> Like concatenation, but for signal_interface objects.  All
        %> signal parameters must match (Rs, Fs, etc.) to avoid an error.
        %>
        %> Example:
        %> @code
        %> sig_big = combine(si1, si2, si3, si4);
        %> @endcode
        %>
        %> @see Combiner_v1::combine
        function obj = combine(varargin)
            obj=Combiner_v1.combine(varargin);
        end

        %> @brief Overload display function
        function disp(obj)
            % Overload display function (for easy viewing in the console and
            % debugger)
            if isreal(get(obj))
                txt_sig = 'Real';
            else
                txt_sig = 'Complex';
            end
            if obj.Fc == 1
                strFc = 'Undefined ';
                strWavelength = 'Undefined ';
            else
                strFc = formatPrefixSI(obj.Fc,'%1.3f');
                strWavelength = formatPrefixSI(const.c/obj.Fc,'%1.5f');
            end
            if obj.Rs == 1
                strRs = 'Undefined ';
                strTs = 'Undefined ';
                strNss = 'Undefined ';
            else
                strRs = formatPrefixSI(obj.Rs,'%1.1f');
                strTs = formatPrefixSI(1/obj.Rs,'%1.1f');
                strNss = formatPrefixSI(obj.Nss,'%1.2f');
            end
            fprintf(1,[
                '%s signal\n' ...
                '              Length: %sSa\n'...
                'Number of components: %d\n'...
                '       Sampling rate: %sHz (%ss)\n'...
                '         Symbol rate: %sBd (%ss)\n'...
                '  Oversampling ratio: %sSa/symbol\n'...
                '   Carrier frequency: %sHz (%sm)\n'...
                '\n' ],...
                txt_sig,...
                formatPrefixSI(obj.L,'%1.0f'),...
                obj.N,...
                formatPrefixSI(obj.Fs,'%1.2f'),formatPrefixSI(obj.Ts,'%1.2f'),...
                strRs, strTs,...
                strNss,...
                strFc, strWavelength);

            disp(obj.P);
        end

        %> @brief Set properties for the current object
        %>
        %> Examples:
        %> @code
        %> signal = set(signal, ones(100, 1);
        %> signal.set(ones(100, 1);
        %> signal = set(signal, 'P', pwr(50, 1));
        %> signal = set(signal, 'E', ones(100, 1), 'P', pwr(50, 1), 'Rs', 50e9);
        %> @endcode
        %> The first two lines are equivalent, and just show the different
        %> main syntax that can be used.  They will set the signal to 100 1's
        %> without changing other properties.
        %> The next two lines are examples of how to change multiple
        %> properties at once.
        %>
        %> Note on power specfication: If both P and PCol are set, values
        %> in PCol take precedence.
        %>
        %> @retval obj signal_interface with changed properties
        function obj = set(obj,varargin)
            rescaleP = 0;
            rescalePCol = 0;
            obj.enforceLhs(nargout);
            if numel(varargin)==1
                obj.E = varargin{1}; % TODO input checking --- can only be a matrix
                if numel(obj.PCol)~=size(obj.E, 2)
                    robolog('The number of "pwr" objects in PCol must match the number of columns of the signal.', 'WRN');
                    robolog('Resetting quasi-arbitrarily.  This warning will become an error in the future.', 'WRN');
                    if numel(obj.PCol)>size(obj.E, 2);
                    	obj.PCol = obj.PCol(1:size(obj.E, 2));
                    else
                        obj.PCol = repmat(obj.P/obj.N, obj.N, 1);
                    end
                    obj.P = setPtot(obj);
                end
            elseif rem(nargin,2)
                for i=1:(nargin-1)/2
                    obj.(varargin{2*i-1}) = varargin{2*i};
                    if strcmp(varargin{2*i-1}, 'P'), rescalePCol=1; end
                    if strcmp(varargin{2*i-1}, 'PCol')
                        if numel(varargin{2*i}) ~= size(obj.E, 2)
                            robolog('The number of "pwr" objects in PCol must match the number of columns of the signal.', 'ERR');
                        end
                        rescaleP=1;
                    end
                end
            else
                robolog('Bad key-value pairs.','ERR');
            end
            if rescaleP, obj.P = setPtot(obj); end
            if rescalePCol, obj.PCol = repmat(obj.P/obj.N, obj.N, 1); end
            if rescalePCol && rescaleP
                robolog('Both power per column and total power were specified.  Power per column takes precedence')
            end
        end

    end

    methods (Access=private,Hidden,Static)

        function enforceLhs(n,minimum)
            %ENFORCELHS   Enforces assignment on the LHS to a certain
            %number of arguments
            if nargin<2
                minimum = 1;
            end
            if n<minimum
                robolog('When using this method, you must ensure that LHS exists. Due to memory considerations, overwriting the original object is recommended.','ERR');
            end
        end

    end

end
