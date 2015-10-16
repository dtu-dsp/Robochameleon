%> @file AdaptiveEqualizer_MMA_RDE_v1.m
%> @brief Radius directed equalization
%>
%> @class AdaptiveEqualizer_MMA_RDE_v1
%> @brief Radius directed equalization
%>
%> @ingroup coreDSP
%>
%> Runs blind adaptive equalization on dual-polarization coherent signals
%> with M>=4.  Equalizer taps are calculated using the first part of the
%> sequence for training, then applied without further adaptation to the
%> rest of the sequence.  For M>4, we bootstrap initially using the
%> constant modulus algorithm (CMA), then after pre-convergence we switch
%> to the multiple-modulus algorithm (MMA).  Training sequence length and
%> pre-convergence length can be set using class properties.
%>
%> __Observations:__
%>
%> 1. There are inherent limitations to blind equalization.  This doesn't
%> attempt to solve any of them.
%> 
%> __Example:__
%> @code
%> paramDSP.eq.iter = 4;        %Run 4 iterations of CMA/MMA on training seq. (default 1)
%> paramDSP.eq.taps = 31;       %number of equalizer taps (default 7)
%> paramDSP.eq.mu = 1e-3;       %update coefficient (default 6e-4)
%> paramDSP.eq.type = 'cma';    %cma or mma
%> paramDSP.eq.h_ortho = true;  %Force-orthogonalize taps to avoid CMA singularity
%> paramDSP.eq.cma_preconv = 10000; %Run CMA this many samples
%> paramDSP.eq.equalizer_conv = 20000; %Train equalizer this many samples
%> paramDSP.eq.constellation = [constref('QAM',16)]; %constellation
%> paramDSP.eq.draw = false;    %disable convergence plotting 
%> paramDSP.eq.operation = 'equalization'; %Run both training and equalization
%> 
%> DSP = AdaptiveEqualizer_MMA_RDE_v1(paramDSP.eq); %construct
%> Signal_after_eq = traverse(DSP, Signal_before_eq);   %run
%> @endcode
%> 
%>
%> @author Edson Porto da Silva
%> @author Robert Borkowski
%> 
%> @version 1
classdef AdaptiveEqualizer_MMA_RDE_v1 < unit

    
    properties
        %> Number of inputs
        nInputs     = 1;
        %> Number of outputs
        nOutputs    = 1;
        
        %> Type {'cma' | 'mma'}
        type        = 'mma';
        %> Reset taps to be orthogonal between training iterations (avoid CMA singularity)  {true | false}
        h_ortho     = true;
        %> Number of taps
        taps        = 7;
        %> Tap update coefficient
        mu          = 6e-4;
        %> CMA pre-convergence length
        cma_preconv    = 1000;
        %> Training period convergence length
        equalizer_conv = 10000;
        %> Number of iterations for training
        iter           = 1;
        %> Vector of symbols in constellation (see constref.m)
        constellation;
        %> Train-only or equalize {'training' | 'equalization'}
        operation = 'equalization';
    end
    
    properties (Hidden=true)
        %> Inital center tap value
        h_init = 1;
        %> Store taps for h_xx
        hxx;
        %> Store taps for h_xy
        hxy;
        %> Store taps for h_yx
        hyx;
        %> Store taps for h_yy
        hyy;
        %> Store ring radii for MMA
        R;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Only constellation is required, everything else has a default
        %> value.  Plotting is on by default, disable using params.draw=0.
        %> 
        %> @param params parameter structure (fields correspond to class properties).
        function obj = AdaptiveEqualizer_MMA_RDE_v1(params)
            if nargin<1, params = {}; end; setparams(obj,params,{'constellation'});
            initialize(obj);
            if isfield(params, {'draw'})
                obj.draw = params.draw;
            else
                obj.draw = 1;   % enables draw by default
            end
            
        end
        
        %> @brief Main routine
        function [out,outNss] = traverse(obj, in)
            [out,outNss] = obj.poldemux_cr_qam_v4_fast(in);
        end
        
        %> @brief Initialize object
        %> 
        %> Set filter taps and check user-specified parameter values.
        function initialize(obj)
            % Initialization
            
            obj.constellation = pwr.normpwr(obj.constellation);
            
            h = zeros(obj.taps,2,2);
            sz = size(obj.h_init);
            mid = ceil((obj.taps+1)/2);
            
            if isfloat(obj.h_init) && isfinite(obj.h_init)
                if isscalar(obj.h_init)
                    h(mid,:,:) = diag([obj.h_init obj.h_init]);
                elseif isvector(obj.h_init)
                    h(mid,:,:) = diag(obj.h_init);
                elseif isequal(sz,[2 2])
                    h(mid,:,:) = obj.h_init;
                elseif isequal(sz,[2 2 obj.taps])
                    h = shiftdim(obj.h_init,2);
                else
                    robolog('Incorrect H_init','ERR');
                end
            else
                robolog('H_init can only be numeric matrix','ERR');
            end
            
            obj.hxx = squeeze(h(:,1,1));
            obj.hxy = squeeze(h(:,1,2));
            obj.hyx = squeeze(h(:,2,1));
            obj.hyy = squeeze(h(:,2,2));
            
            % Equalizer parameters
            if isscalar(obj.mu)
                obj.mu = repmat(obj.mu,[2 2]);
            elseif isvector(obj.mu) && numel(obj.mu)==2
                obj.mu = [obj.mu(1) obj.mu(2);...
                    obj.mu(2) obj.mu(1)];
            elseif ~(ismatrix(obj.mu) && isequal(size(obj.mu),[2 2]))
                robolog('Incorrect mu.','ERR');
            end
            
            if strcmpi(obj.type,'cma')
                obj.R = 1;
            elseif strcmpi(obj.type,'mma')
                obj.R = uniquetol( abs(obj.constellation), 1e-8 );
            else
                robolog('Incorrect equalizer type: %s.','ERR',obj.type);
            end
        end
        
        %> @brief Equalization routine
        %> 
        %> Equalizer taps are calculated using the first part of the sequence 
        %> for training, then applied without further adaptation to the
        %> rest of the sequence.  For M>4, on the first training iteration,
        %> we bootstrap with CMA.  Between iterations, the last value of
        %> the taps is retained. If obj.h_ortho is false, this is done
        %> for all filters; if it is true, we take h.yy = conj(h.xx) and
        %> h.yx = -conj(h.xy).
        %>
        %> @param in input signal
        %> @retval out1 equalized output at 1 sample per symbol
        %> @retval outNss equalized output at same oversampling rate as input
        function [out1,outNss] = poldemux_cr_qam_v4_fast(obj,in)
     
            % Power normalization to 1 per polarization.
            in = in.fun1(@(x)pwr.normpwr(x));
            
            mma = numel(obj.R)>1;
            R2 = obj.R'.^2;
            
            if size(R2, 2) > 1
                i = ones(1, 2)*floor(size(R2,2)/2 + 1);
            else
                i = [1 1];
            end
            
            % Defining training parameters:
            L = fix((obj.equalizer_conv-obj.taps)/in.Nss+1);
            E_hat = nan(L,2);
            errsq = nan(L+1,2);
            E_Nss = zeros(size(in.E));
            
            % Equalizer training section:
            for iter_k=1:obj.iter
                robolog('Equalizer training iteration #%d.','NFO', iter_k)
                temp = (1:obj.taps); % modified for speed
                temp1 = in.Nss;      % modified for speed
                fieldtemp = in.E;    % modified for speed
                for n=1:L
                    idx = temp+(n-1)*temp1; % Selects the window of samples to equalize
                    field = fieldtemp(idx,:);    % modified for speed
                    E_tmp(:,1) = sum([obj.hxx obj.hxy].*field,2); % Faster than matrix multiplication
                    E_tmp(:,2) = sum([obj.hyx obj.hyy].*field,2);
                    
                    E_hat(n,:) = sum(E_tmp,1); % Equalized output
                    
                    A = abs(E_hat(n,:));       % X
                    
                    if n>obj.cma_preconv || iter_k > 1
                        if mma, [~,i] = min(ipdm(obj.R,A')); end % Radious choice for MMA taps adaptation
                        %                 else
                        %                     E_tmp = in.E(idx,:);
                    end
                    
                    %
                    errsq(n,:) = R2(i)-A.^2; % Calculates the square error accordind to the CMA|MMA rules.
                    
                    % Adaptive step size for the equalizer error update (to implement!!):
                    e_xx = errsq(n,1);
                    e_yx = errsq(n,2);
                    e_xy = errsq(n,1);
                    e_yy = errsq(n,2);
                    
                    E_Nss(idx,:) = E_Nss(idx,:) + E_tmp;
                    
                    % Update the equalizer taps:
                    obj.hxx = obj.hxx + obj.mu(1)*e_xx*E_hat(n,1)*conj(fieldtemp(idx,1));
                    obj.hyx = obj.hyx + obj.mu(2)*e_yx*E_hat(n,2)*conj(fieldtemp(idx,1));
                    obj.hxy = obj.hxy + obj.mu(3)*e_xy*E_hat(n,1)*conj(fieldtemp(idx,2));
                    obj.hyy = obj.hyy + obj.mu(4)*e_yy*E_hat(n,2)*conj(fieldtemp(idx,2));
                    
                    if n==obj.cma_preconv && obj.h_ortho
                        % Set Y polarization to be orthogonal to X to avoid
                        % converging to the same polarization (CMA singularity avoidance)
                        obj.hxy = -conj(obj.hyx);
                        obj.hyy =  conj(obj.hxx);
                    end
                end
                robolog('Equalizer MSE = %.6f.', mean(mean(errsq(1:end-1,:))))
                obj.results.errsq = errsq;
            end
            robolog('Equalizer training completed.','NFO')
            
            
            qqq = obj.taps-in.Nss-2;
            qqq2 = repmat(1:qqq,in.Nss,1);
            qqq2 = qqq2(:);
            kuk = repmat(qqq,in.Nss,1); kuk(1) = kuk(1)+1;
            kuk = repmat(kuk,ceil(in.L/in.Nss),1);
            kuk = kuk(1:in.L);
            kuk(1:numel(qqq2)) = qqq2;
            kuk(end-numel(qqq2)+1:end) = flipud(qqq2);
            
            E_Nss = bsxfun(@rdivide,E_Nss,kuk);
            
            
            
            if any(isnan(E_hat))
                robolog('FIR filter taps for polarization demultiplexing did not converge.','ERR')
            end
            
            
            % Filtering section:
            L = fix((in.L-obj.taps)/in.Nss+1);
            E_hat_out = nan(L,2);
            
            robolog('Equalization started.','NFO')
            if ~strcmp(obj.operation, 'training')
                temp = (1:obj.taps);        % modified for speed
                temp1 = in.Nss;             % modified for speed
                temp2 = [obj.hxx obj.hxy];  % modified for speed
                temp3 = [obj.hyx obj.hyy];  % modified for speed
                fieldtemp = in.E;           % modified for speed
                for n=1:L
                    idx = temp+(n-1)*temp1;     % Selects the window of samples to equalize
                    field = fieldtemp(idx,:);   % modified for speed
                    E_tmp(:,1) = sum(temp2.*field,2); % Faster than matrix multiplication
                    E_tmp(:,2) = sum(temp3.*field,2);
                    E_hat_out(n,:) = sum(E_tmp,1);
                end
                robolog('Equalization completed.')
            else
                E_hat_out = zeros(L,2);
            end            
            
            out1 = in.set('E', E_hat_out, 'Fs', in.Rs);
            outNss = in.set(E_Nss);
            
            if obj.draw
                plotConv(obj);
            end
        end
        
        %> @brief Plot equalizer convergence
        function f = plotConv(obj)
            WND_L=3000;
            L = size(obj.results.errsq,1);
            eq_err_x = conv(abs(obj.results.errsq(:,1)).^2,rectwin(WND_L)/WND_L,'valid');
            eq_err_y = conv(abs(obj.results.errsq(:,2)).^2,rectwin(WND_L)/WND_L,'valid');
            
            f = figure('Name', 'RDE convergence');
            clf(f);
            axes1 = axes('Parent',f,'YGrid','on','XGrid','on');
            box(axes1,'on');
            hold(axes1,'all');
            plot(WND_L:L,10*log10(eq_err_x),'Parent',axes1,...
                'Color',[0 0 1],...
                'LineWidth',2,...
                'DisplayName','X');
            plot(WND_L:L,10*log10(eq_err_y),'Parent',axes1,...
                'Color',[1 0 0],...
                'LineWidth',2,...
                'DisplayName','Y');
            xlabel('Time, Sa');
            ylabel('Mean square error, dB');
            title(sprintf('%d-point moving average of equalizer error',WND_L));
            legend(axes1,'show');
            %     hold(axes1,'off');
        end
        
        %> @brief Plot filter taps
        function f = plotTaps(obj)
            f = figure('Name', 'RDE taps');
            subplot(2,2,1); plot(cplx2mat(obj.hxx)); title('h_{xx}');
            subplot(2,2,2); plot(cplx2mat(obj.hxy)); title('h_{xy}');
            subplot(2,2,3); plot(cplx2mat(obj.hyx)); title('h_{yx}');
            subplot(2,2,4); plot(cplx2mat(obj.hyy)); title('h_{yy}');
        end
        
    end
end