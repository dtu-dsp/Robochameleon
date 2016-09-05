%> @file Decimate_v1.m
%> @brief Decimator
%>
%> @class Decimate_v1
%> @brief Decimator
%>
%> @ingroup coreDSP
%> 
%> Performs decimation according to the user-specified criterion.
%>
%>
%> __Example:__
%> @code
%>   param.Nss      = 2;    %number of samples per symbol out
%>   param.method = 'gardner'   %criterion
%>
%>   decimator = Decimate_v1(param);
%>
%>   param.sig.L = 10e6;
%>   param.sig.Fs = 64e9;
%>   param.sig.Fc = 193.1e12;
%>   param.sig.Rs = 10e9;
%>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%>   Ein = rand(1000,2);
%>   sIn = signal_interface(Ein, param.sig);
%>
%>   sigOut = decimator.traverse(sigIn);
%> @endcode
%>
%> @version 3
classdef Decimate_v1 < unit
    
    properties
        nInputs = 1;
        nOutputs = 1;
        
        %> Target Nss
        Nss = 1; 
        %> Decimate each signal component separately or choose same point for all? {'separate'|'joint'}
        mode = 'separate';
        %> Offset wrt. found sampling point (in samples)
        offset = 0;
        %> Decimation method
        method = 'variance';
    end

    
    
    methods
        
        %> @brief Class constructor
        %>
        %> Constructs an object of type Decimate_v1
        %>
        %> @param param.Nss          Target number of samples per symbol out. [Default: 1]
        %> @param param.offset       Number of samples to shift by [Default: 0].
        %> @param param.method       Decimation criterion {'variance' | 'gardner' | 'SLN' | 'gardner4nyquist'}. [Default: variance]
        %>
        %> @retval obj      An instance of the class Decimate_v1
        function obj = Decimate_v1(param)
            if nargin<1, param = {}; end; obj.setparams(param);
        end
        
        %> @brief Chooses a decimator, decimates, plots
        %>
        %> @param in signal to be decimated
        %>
        %> @retval out downsampled signal
        function out = traverse(obj,in)
            s = cell(1,in.N);
            for i=1:in.N
                if strcmpi(obj.mode, 'separate')||i==1
                    if numel(obj.offset)>1
                        colwiseOffset = obj.offset(i);
                    else
                        colwiseOffset = obj.offset;
                    end
                    switch obj.method
                        case 'variance'
                            [s{i},idx,symb] = obj.decimate(in.E(:,i),in.Nss,obj.Nss,colwiseOffset);
                        case 'gardner'
                            [s{i},idx,symb] = obj.GardDecimate(in.E(:,i),in.Nss,obj.Nss,colwiseOffset);
                        case 'gardner4nyquist'
                            [s{i},idx,symb] = obj.NyquistGardDecimate(in.E(:,i),in.Nss,obj.Nss,colwiseOffset);
                        case 'SLN'
                            [s{i},idx,symb] = obj.SLNDecimate(in.E(:,i),in.Nss,obj.Nss,colwiseOffset);
                        otherwise
                            [s{i},idx,symb] = obj.decimate(in.E(:,i),in.Nss,obj.Nss,colwiseOffset);
                    end
                else
                    s{i} = in.E(idx(1):in.Nss/obj.Nss:end, i);
                    if length(s{1})<length(s{i})
                        data = s{i};
                        s{i} = data(1:length(s{1}));
                    else
                        data = s{1};
                        s{1} = data(1:length(s{i}));
                    end
                    Lmax = min(in.L, 1e5*in.Nss);
                    Lmax = Lmax-mod(Lmax, in.Nss);
                    symb = reshape(in.E(1:Lmax, i),in.Nss,[]).';
                end
                if obj.draw
                    if ~isreal(symb), symb = abs(symb).^2; end
                    idx = idx(idx<=in.Nss);
                    spsz{1} = ceil(sqrt(in.Nss));
                    spsz{2} = ceil(in.Nss/spsz{1});
                    
                    fig_hist = figure('Color',[1 1 1]);
                    for sp_idx = 1:in.Nss
                        sp2 = axes('Parent',fig_hist,'ZTick',zeros(1,0),'YTick',zeros(1,0),...
                        'XTick',zeros(1,0),'Position',[mod(sp_idx-1,spsz{1})/spsz{1} 1-fix((sp_idx-1)/spsz{2}+1)/spsz{2} 1/spsz{1} 1/spsz{2}]);
                        hold(sp2,'on');
                        box(sp2,'on');
%                         plot(symb(:,sp_idx),'MarkerSize',1,'Marker','.','LineStyle','none','Color',color)
                        if any(idx==sp_idx), color='r'; else color='b'; end
                        [n,xout] = hist(symb(:,sp_idx),100);
                        plot(xout,n,'Color',color);
%                         set(,'Color',color);
                    end
                end
            end
            out = in.set(cell2mat(s));
            out = out.set('Fs', obj.Nss/in.Nss*in.Fs);
            
           %             
%             out = sig.fun1(@(x)obj.decimate(x, in.Nss, obj.Nss, obj.offset));
%             out = out.set('Fs', obj.Nss/in.Nss*in.Fs); 
                
        end
        
    end
    
        
    methods (Static)
        
        %> @brief Decimation by the maximum variance method
        %>
        %> @param x signal to be decimated
        %> @param Nss_in Number of samples per symbol in
        %> @param Nss_out Number of samples per symbol out
        %> @param offset offset to apply
        %>
        %> @retval out downsampled signal
        %> @retval idx sampling point
        %> @retval symbols reshaped input
        function [out, idx, symbols] = decimate(x, Nss_in, Nss_out, offset)
            if ~isvector(x)
                warning('Input signal should be a vector.');
            end
            if nargin<3 || isempty(Nss_out), Nss_out = 1; end
            r = Nss_in/Nss_out;
            if ~iswhole(r,1e-9)
                error('Ratio of the number of input to output samples must be an integer.');
            end
            if nargin<4, offset = 0; end
            N = Nss_in*fix(numel(x)/Nss_in);
            %FIXME Two lines below: quick fix for out of memory errors          
            x = x(1:N);
            
            SYMBOLS_LIMIT = 1e5;
%             LIM = Nss_in*fix(SYMBOLS_LIMIT/Nss_in);
            LIM = SYMBOLS_LIMIT*Nss_in;
            LIM = min(LIM,N);
            
            symbols = reshape(x(1:LIM),Nss_in,[]).'; % reshape signal into columns (column=symbol)
            
            [~,ptr] = max(var(symbols)); % find maximum variance point
            ptr = mod(ptr-1+offset,r)+1;
            idx = ptr:r:N;
            out = x(idx);
            
            % Fine tunning test:
%             testClk = repmat([1 0],1, length(out/2));
%             testSig = out/max(abs(out));
%             plot(xcorr(testClk(1:1000), testSig(1:1000)));
            %testVariance = var(out)
            
        end
        
        %> @brief Decimation using Gardner criteria
        %>
        %> Reference: F. Gardner, "A BPSK/QPSK Timing-Error Detector for Sampled Receivers," IEEE Trans. Commun., vol. 34, no. 5, pp. 423–429, May 1986.
        %>
        %> @param x signal to be decimated
        %> @param Nss_in Number of samples per symbol in
        %> @param Nss_out Number of samples per symbol out
        %> @param offset offset to apply
        %>
        %> @retval out downsampled signal
        %> @retval idx sampling point
        %> @retval symbols reshaped input
        function [out, idx, symbols]= GardDecimate(x, Nss_in, Nss_out, offset)
             if ~isvector(x)
                warning('Input signal should be a vector.');
            end
            if nargin<3 || isempty(Nss_out), Nss_out = 1; end
            r = Nss_in/Nss_out;
            if ~iswhole(r,1e-9)
                error('Ratio of the number of input to output samples must be an integer.');
            end
            if nargin<4, offset = 0; end
            if mod(Nss_in, 2), error('Input Nss must be even'); end
            N = Nss_in*fix(numel(x)/Nss_in);
            x = x(1:N);
            symbols = buffer(x,2*Nss_in+1, 1, 'nodelay'); % reshape signal into columns (column=symbol)
            cstart=Nss_in/2;
            for jj=1:Nss_in
                err_gard(jj) = mean(real((symbols(cstart+jj-Nss_in/2, :)-symbols(cstart+jj+Nss_in/2, :)).*conj(symbols(cstart+jj, :))));
               % var_err_gard(jj) = var(real((symbols(cstart+jj-Nss_in/2, :)-symbols(cstart+jj+Nss_in/2, :)).*conj(symbols(cstart+jj, :))));
            end
                        
            [~,ptr] = min(abs(err_gard)); % find maximum variance point
            ptr = mod(ptr-1+offset,r)+1;
            idx = ptr:r:N;
            out = x(idx);
            symbols = symbols.';
        end
        
        %> @brief Decimation using Nyquist/Gardner criteria
        %>
        %>
        %> @param x signal to be decimated
        %> @param Nss_in Number of samples per symbol in
        %> @param Nss_out Number of samples per symbol out
        %> @param offset offset to apply
        %>
        %> @retval out downsampled signal
        %> @retval idx sampling point
        %> @retval symbols reshaped input
        function [out, idx, symbols]= NyquistGardDecimate(x, Nss_in, Nss_out, offset)
             if ~isvector(x)
                warning('Input signal should be a vector.');
            end
            if nargin<3 || isempty(Nss_out), Nss_out = 1; end
            r = Nss_in/Nss_out;
            if ~iswhole(r,1e-9)
                error('Ratio of the number of input to output samples must be an integer.');
            end
            if nargin<4, offset = 0; end
            if mod(Nss_in, 2), error('Input Nss must be even'); end
            N = Nss_in*fix(numel(x)/Nss_in);
            x = x(1:N);
            symbols = buffer(x,2*Nss_in+1, 1, 'nodelay'); % reshape signal into columns (column=symbol)
            cstart=Nss_in/2;
            for jj=1:Nss_in
                err_gard(jj) = mean(real((symbols(cstart+jj-Nss_in/2, :).*conj(symbols(cstart+jj-Nss_in/2, :))...
                                         -symbols(cstart+jj+Nss_in/2, :).*conj(symbols(cstart+jj+Nss_in/2, :)))...
                                         .*conj(symbols(cstart+jj, :)).*symbols(cstart+jj, :)));
                                     
                var_err_gard(jj) = var(real((symbols(cstart+jj-Nss_in/2, :).*conj(symbols(cstart+jj-Nss_in/2, :))...
                                         -symbols(cstart+jj+Nss_in/2, :).*conj(symbols(cstart+jj+Nss_in/2, :)))...
                                         .*conj(symbols(cstart+jj, :)).*symbols(cstart+jj, :)));
            end
            
            %figure, plot(err_gard, '-o');
            %figure, plot(var_err_gard, 'r-o');            
            %var_gard = sum(var_err_gard)
            
            crossPoint = (1:1:N);
            signum = sign(err_gard);	               % get sign of data
            signum(x==0) = 1;	                       % set sign of exact data zeros to positive
            ptr = max(crossPoint(diff(signum)~=0));	   % get zero crossings by diff ~= 0            
                       
            % Fine sample adjust in the crossing point
            if abs(err_gard(ptr)) > abs(err_gard(ptr + 1))
                ptr = ptr + 1;
            elseif ptr > 1
                if abs(err_gard(ptr)) > abs(err_gard(ptr - 1)) 
                ptr = ptr - 1;
                end
            end
            
            if isempty(ptr)
                [~,ptr] = min(abs(err_gard)); % find maximum variance point
            end
            x = circshift(x, ptr);            
            idx = 1:r:N;
            
           % [~,ptr] = min(abs(err_gard(1:Nss_in/2))) % find maximum variance point
           % ptr = mod(ptr-1+offset,r)+1
           % idx = ptr:r:N;
           %var_sig = abs(var(abs(x(idx)).^2))
           out = x(idx);
        end
        
        %> @brief Decimation using SLN criteria
        %>
        %> SLN = "square law nonlinearity"
        %>
        %> Reference: M. Oerder and H. Meyr, “Digital filter and square timing recovery,” IEEE Trans. Commun. 36(5), 605–61 (1988).
        %>
        %> @param x signal to be decimated
        %> @param Nss_in Number of samples per symbol in
        %> @param Nss_out Number of samples per symbol out
        %> @param offset offset to apply
        %>
        %> @retval out downsampled signal
        %> @retval idx sampling point
        %> @retval symbols reshaped input
        function [out, idx, symbols]= SLNDecimate(x, Nss_in, Nss_out, offset)
            if ~isvector(x)
                warning('Input signal should be a vector.');
            end
            if nargin<3 || isempty(Nss_out), Nss_out = 1; end
            r = Nss_in/Nss_out;
            if ~iswhole(r,1e-9)
                error('Ratio of the number of input to output samples must be an integer.');
            end
            if nargin<4, offset = 0; end
            if mod(Nss_in, 4), error('Input Nss must be a multiple of 4'); end
            N = Nss_in*fix(numel(x)/Nss_in);
            x = x(1:N);
            symbols = buffer(x,2*Nss_in+1, 1, 'nodelay').'; % reshape signal into columns (column=symbol)
            for jj=1:Nss_in
                err_SLN(jj) = mean(angle(abs(symbols(:, jj:Nss_in/4:jj+Nss_in-1)).^2*exp(-1i*.5*pi*(0:3)).'));
            end
            [~,ptr] = min(abs(err_SLN)); % find maximum variance point
            ptr = mod(ptr-1+offset,r)+1;
            idx = ptr:r:N;
            out = x(idx);
        end
        
    end
end