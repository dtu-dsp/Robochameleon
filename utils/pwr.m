%>@file pwr.m
%>@brief pwr class definition
%>
%>@class pwr
%>@brief power description class
%> 
%> @ingroup base
%>
%> pwr describes the signal power and signal-to-noise ratio.  It also has a 
%> number of useful power-related methods.  Many parameters are specified
%> as strings.  None are case-sensitive.
%> 
%> Example
%> @code
%> P1 = pwr(50, 5);
%> P2 = pwr(-50, {1, 'mw'});
%> P3 = P1+P2;
%> @endcode
%> will create:
%>  P1, a power object describing a signal (50 dB SNR, 5dBm power)
%>  P2, a power object describing noise (-50dB SNR, 0 dBm power)
%> then add them, returning P3, which should have about 5dB SNR, 6dBm total
%> power
%>
%> @author Robert Borkowski
%> @version 1
classdef pwr
    
    properties (SetAccess=immutable,Hidden=true)
        %> Total power, dBW
        P_dBW;
        %> Signal-to-noise ratio, dB
        SNR_dB; 
    end
    
    methods (Access=private,Hidden=true,Static=true)
        
        %> @brief validate power
        %>
        %> Check if power value is acceptable (real, scalar)
        function res = validpwr(P)
            res = false;
            if isscalar(P) && isreal(P), res = true; end
        end
        
        %> @brief Parse format to get power
        %>
        %> Convert power in dBW to desired format
        %>
        %> @param P_dBW power in dBW
        %> @param varargin string describing power unit {'dBm' | 'w' | 'mw' | 'uw' | 'dbw' | 'dbu'}
        %> @retval P_format formatted power
        function P_format = outputP(P_dBW,varargin)
            type = defaultargs('dBm',varargin{:});
            switch lower(type)
                case 'w'
                    P_format = dB2lin(P_dBW);
                case 'mw'
                    P_format = dB2lin(P_dBW)*1e3;
                case 'uw'
                    P_format = dB2lin(P_dBW)*1e6;
                case 'dbw'
                    P_format = P_dBW;
                case 'dbm'
                    P_format = P_dBW+30;
                case 'dbu'
                    P_format = P_dBW+60;
                otherwise
                    error('Power unit can be W, mW, uW, dBW, dBm or dBu.');
            end
        end
        
        %> @brief Parse format to get SNR
        %>
        %> Convert SNR in dB to desired format
        %>
        %> @param SNR_dB SNR in dB
        %> @param varargin string describing SNR unit {'dB' | 'lin'}
        %> @retval SNR_format formatted SNR
        function SNR_format = outputSNR(SNR_dB,varargin)
            type = defaultargs('dB',varargin{:});
            switch lower(type)
                case 'lin'
                    SNR_format = dB2lin(SNR_dB);
                case 'db'
                    SNR_format = SNR_dB;
                otherwise
                    error('SNR unit can be lin for linear or dB.');
            end
        end
        
        %> @brief Parse format to set power
        %>
        %> Convert power and specified format to dBW - default dBm
        %>
        %> @param P power in dBm as scalar or cell array with scalar + unit
        %> @retval P_dB power in dBW
        function P_dB = inputP(P)
            if pwr.validpwr(P)
                type = 'dBm';
            elseif iscell(P) && numel(P)==2 && pwr.validpwr(P{1}) && ischar(P{2})
                type = lower(P{2});
                P = P{1};
            else
                error('Power must be specified as a real scalar (in dBm) or a cell array must be constructed as {value,unit}');
            end
            switch lower(type)
                case 'w'
                    P_dB = lin2dB(P);
                case 'mw'
                    P_dB = lin2dB(P/1e3);
                case 'uw'
                    P_dB = lin2dB(P/1e6);
                case 'dbw'
                    P_dB = P;
                case 'dbm'
                    P_dB = P-30;
                case 'dbu'
                    P_dB = P-60;
                otherwise
                    error('Power unit can be W, mW, uW, dBW, dBm or dBu.');
            end
        end
        
        %> @brief Parse format to set SNR
        %>
        %> Convert SNR and specified format to dB - default dB
        %>
        %> @param SNR SNR in dB as scalar or cell array with scalar + unit
        %> @retval SNR_dB SNR in dB
        function SNR_dB = inputSNR(SNR)
            if pwr.validpwr(SNR)
                type = 'dB';
            elseif iscell(SNR) && numel(SNR)==2 && pwr.validpwr(SNR{1}) && ischar(SNR{2})
                type = lower(SNR{2});
                SNR = SNR{1};
            else
                error('SNR must be specified as a real scalar (in dB) or a cell array must be constructed as {value,unit}.');
            end
            switch lower(type)
                case 'lin'
                    SNR_dB = lin2dB(SNR);
                case 'db'
                    SNR_dB = SNR;
                otherwise
                    error('SNR unit can be lin for linear or dB.');
            end
        end
        
        
        
    end
    
    methods (Static=true)
        
        %> @brief normalize signal based on power
        %>
        %> Normalize signal based on calculated power
        %>
        %> Example
        %> @code
        %> s1= rand(10,2);
        %> [y1, scfactor] = pwr.normpwr(s1, 'max', 1, 'linear');
        %> [y2, scfactor2] = pwr.normpwr(s1, 'average', 1, 'linear');
        %> [y3, scfactor3] = pwr.normpwr(s1);
        %> @endcode
        %> y1 is normalized so that its peak power is 1
        %> y2 is normalized so that its average power is 1
        %> y3 = y2
        %>
        %> @param x signal
        %> @param type signal property (power) to normalize {'average' | 'max'}
        %> @param P power to normalize to (scalar)
        %> @param unit unit power is specified in  {'linear' | 'db' | 'dBm'}
        %> @retval y normalized signal
        %> @retval scfactor scaling factor
        function [y,scfactor] = normpwr(x,varargin)
            [type,P,unit] = defaultargs({'average',1,'linear'},varargin);

            switch lower(unit)
                case {'linear','lin'}
                    P_ = P;

                case {'db'}
                    P_ = 10^(P/10);

                case {'dbm'}
                    P_ = 1e-3*10^(P/10);

                otherwise
                    error('Unit must be ''linear'', ''dB'' or ''dBm''.');
            end
    
            % TODO Handling real and complex cases
            [Pav,~,Prange] = pwr.meanpwr(x(:));
            switch lower(type)
                case {'average','avg'}
                    scfactor = Pav/P_;

                case {'maximum','max'}
                    scfactor = Prange(2,:)/P_;

                otherwise
                    error('Normalization type must be ''average'' or ''maximum''.');
            end

%             y = bsxfun(@mrdivide,x,sqrt(scfactor));
            y = x/sqrt(scfactor);
        end

        %> @brief   Mean signal power and energy
        %>
        %> Mean signal power and energy
        %> Example
        %> @code
        %>   [P,E] = pwr.meanpwr(X)
        %> @endcode
        %>
        %> @param x complex or real input signal
        %> @retval P signal power
        %> @retval E signal energy
        %> @retval Prange minimum and maximum signal powers
        %> @retval Ppeak peak signal power
        function [P,E,Prange,Ppeak] = meanpwr(x)
            
            if isvector(x)
                L = numel(x);
            else
                L = size(x,1);
            end
            %absxsq = abs(x).^2;
            absxsq = x.*conj(x);        %faster
            Ppeak = max(absxsq);
            E = sum(absxsq);
%             if isreal(x)
%                 E = E/2;
%             end
            P = E/L;
            Prange = findrange(absxsq);
        end
        
        %> @brief get OSNR
        %>
        %> @param sig A signal_inteface to retrieve the signal bandwidth.
        %> @param varargin{1} String describing SNR unit {'dB' | 'lin'}. [Default: dB]
        %> @param varargin{2} Bandwidth over which evaluate the OSNR [nm]. [Default: 0.1]
        %>
        %> @retval OSNR The signal OSNR evaluated over the given bandwidth
        function OSNR = getOSNR(sig, varargin)
            if nargin < 3
                NBW = 0.1;
            else
                NBW = varargin{2};
            end
            if sig.Fc == 0
                robolog('The signal carrier frequency is required to compute the noise bandwidth', 'ERR');
            end
            lambda = const.c/sig.Fc;
            NBW_Hz = const.c./(lambda-.5*1e-9*NBW)-const.c./(lambda+.5*1e-9*NBW);
            OSNR_dB = sig.P.SNR+10*log10(sig.Fs/NBW_Hz);
            if nargin > 1
                OSNR = pwr.outputSNR(OSNR_dB,varargin(1));
            else
                OSNR = pwr.outputSNR(OSNR_dB,{});
            end
        end
        
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Constructs an object of type pwr.  Example:
        %> @code
        %> P1 = pwr(50, 0);
        %> P2 = pwr(50, {1, 'mw'});
        %> P3 = pwr({1e5, 'lin'}, {1, 'mw'});
        %> @endcode
        %> These statements are equivalent
        %> 
        %> @param SNR if scalar, SNR in dB.  Otherwise, cell array {value, unit}
        %> @param P if scalar, power in dBm.  Otherwise, cell array {value, unit}
        %> @retval obj object of power type
        function obj = pwr(SNR,P)
            if nargin<1
                error('Signal-to-noise ratio must be specified.');
            elseif nargin<2
                P = 0;
            end
            obj.SNR_dB = pwr.inputSNR(SNR);
            obj.P_dBW = pwr.inputP(P);
        end

        %> @brief Add two power objects
        %> @param obj1 addend power object (single)
        %> @param obj2 addend power object (single)
        %> @retval obj object of power type
        function obj = plus_1elem(obj1,obj2)
            Ps = obj1.Ps('W')+obj2.Ps('W');
            Pn = obj1.Pn('W')+obj2.Pn('W');
            %zero total power is a special case
            if isinf(log10(Ps))&&isinf(log10(Pn))
                obj = pwr(0, -Inf);
            else
                obj = pwr({Ps/Pn,'lin'},{Ps+Pn,'W'});
            end
        end
        
        %> @brief Add two power objects, with support for arrays of objects
        %> @param obj1 addend power object
        %> @param obj2 addend power object
        %> @retval obj object of power type
        function obj = plus(obj1, obj2)
            if numel(obj1)~=numel(obj2)
                error('When adding two power object arrays, number of elements in array 1 must equal number of elements in array 2');
            end
            obj = plus_1elem(obj1(1), obj2(1));
            for jj=2:numel(obj1)
                obj(jj) = plus_1elem(obj1(jj), obj2(jj));
            end
            
        end
        
        %> @brief Subtract two power objects
        %> 
        %> Subtract two power objects - do not do this, it doesn't make
        %> sense.
        function obj = minus(obj1,obj2)
            warning('Subtraction is equivalent to addition -- no correlation.')
            obj = plus(obj1,obj2);
        end
        
        %> @brief Multiply a power object by a scalar
        %> 
        %> Multiply a power object by a scalar.  Useful for gain, loss.
        %>
        %> @param in1 multiplicand (power object or scalar)
        %> @param in2 multiplicand (power object or scalar)
        %> @retval obj object of power type
        function obj = mtimes(in1,in2)
            if isa(in1, 'pwr')&&~isa(in2, 'pwr')
                Ps = dB2lin([in1.P_dBW])*in2;
                SNR = [in1.SNR_dB];
            elseif ~isa(in1, 'pwr')&&isa(in2, 'pwr')
                Ps = in1*dB2lin([in2.P_dBW]);
                SNR = [in2.SNR_dB];
            end
            for jj=1:numel(Ps)
                obj(jj) = pwr(SNR(jj), {Ps(jj), 'W'});
            end
        end
        
        %> @brief Multiply an array of power objects by an array of scalars
        %> 
        %> Multiply an array of power objects by an array of scalars. 
        %>
        %> @param in1 multiplicand (power object or scalar)
        %> @param in2 multiplicand (power object or scalar)
        %> @retval obj object of power type
        function obj = times(in1, in2)
            if numel(in1)==numel(in2)
                for jj=1:numel(in1), obj(jj) = in1(jj)*in2(jj); end
            elseif (numel(in1)==1)||(numel(in2)==1)
                if numel(in1)==1
                    for jj=1:numel(in2), obj(jj) = in1*in2(jj); end
                else
                    for jj=1:numel(in1), obj(jj) = in1(jj)*in2; end
                end
            else
                error('Matrix dimensions must agree');
            end
        end
        
        %> @brief Divide a power object by a scalar
        %>
        %> Divide a power object by a scalar.  Useful for gain, loss.
        %>
        %> @param in1 multiplicand (power object or scalar)
        %> @param in2 multiplicand (power object or scalar)
        %> @retval obj object of power type
        function obj = mrdivide(in1, C)
            obj = mtimes(in1, 1/C);
        end
        
        %> @brief Depreciated get for power
        function P = P(obj,varargin)
            warning('Please use Ptot instead of P function of pwr.');
            P = Ptot(obj,varargin{:});
        end

        %> @brief get SNR
        function SNR = SNR(obj,varargin)
            SNR = pwr.outputSNR(obj.SNR_dB,varargin);
        end

        %> @brief get total power
        %> 
        %> Returns total (signal+noise) power in desired format (default dBm)
        %>
        %> @param obj power object
        %> @param varargin string describing power unit {'dBm' | 'w' | 'mw' | 'uw' | 'dbw' | 'dbu'}
        %> @retval Ptot formatted signal+noise power
        function Ptot = Ptot(obj,varargin)
            Ptot = pwr.outputP(obj.P_dBW,varargin);
        end
        
        %> @brief get signal power
        %> 
        %> Returns signal power in desired format (default dBm)
        %> 
        %> @param obj power object
        %> @param varargin string describing power unit {'dBm' | 'w' | 'mw' | 'uw' | 'dbw' | 'dbu'}
        %> @retval Ps formatted signal power
        function Ps = Ps(obj,varargin)
            if isinf(obj.SNR('lin')) % If SNR is infinite, there is no noise, so Ps = P;
                Ps = obj.Ptot('dBW');
            else
                Ps = obj.Ptot('dBW')+obj.SNR('dB')-10*log10(obj.SNR('lin')+1);
            end
            Ps = pwr.outputP(Ps,varargin);
        end
        
        %> @brief get noise power
        %> 
        %> Returns noise power in desired format (default dBm)
        %> 
        %> @param obj power object
        %> @param varargin string describing power unit {'dBm' | 'w' | 'mw' | 'uw' | 'dbw' | 'dbu'}
        %> @retval Pn formatted signal power
        function Pn = Pn(obj,varargin)
            Pn = pwr.outputP(obj.Ptot('dBW')-10*log10(obj.SNR('lin')+1),varargin);
        end
        
        %> @brief display function
        function obj = disp(obj)
            print_obj = @(obj)fprintf(1,'Total power: %1.2f dBm (%1.2f mW)\nSNR: %1.2f dB (%1.2f)\nSignal power: %1.2f dBm (%1.2f mW)\nNoise power: %1.2f dBm (%1.2f mW)\n',...
                obj.Ptot('dBm'),obj.Ptot('mW'),obj.SNR('dB'),obj.SNR('lin'),obj.Ps('dBm'),obj.Ps('mW'),obj.Pn('dBm'),obj.Pn('mW'));
            if numel(obj)==1
                print_obj(obj);
            else
                for jj=1:numel(obj)
                    fprintf(1, 'Power in signal %d:\n', jj);
                    print_obj(obj(jj))
                    fprintf(1, '\n');
                end
            end
        end
        
    end
    
end
