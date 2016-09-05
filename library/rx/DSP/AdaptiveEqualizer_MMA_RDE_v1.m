%> @file AdaptiveEqualizer_MMA_RDE_v1.m
%> @brief Radius directed equalization
%>
%> @class AdaptiveEqualizer_MMA_RDE_v1
%> @brief Radius directed equalization
%>
%> @ingroup coreDSP
%>
%> Runs blind adaptive equalization on dual-polarization coherent signals
%> with M>=4.  Equalization is split into a training part and a main
%> filtering part.  There are two ways to perform training and three ways
%> to do the main equalization:
%> 
%> Training modes:
%> 1. blind: Radius is chosen based on minimum Euclidean distance criteria
%> 2. dataAided: Radius is chosen based on training sequence provide by
%> user
%>
%> In blind training mode, for M>4, we bootstrap initially using the
%> constant modulus algorithm (CMA), then after pre-convergence we switch
%> to the multiple-modulus algorithm (MMA).  Training sequence length and
%> pre-convergence length can be set using class properties.
%>
%> Equalization modes:
%> 1. training: train-only.  In this case, there is still an output signal,
%> and it is the estmated field during training.
%> 2. equalization: Equalizer taps are calculated using the first part of the
%> sequence for training, then applied without further adaptation to the
%> rest of the sequence.  
%> 3. semiadaptive: Training is performed as usual to initialize, but taps 
%> are also updated over the whole sequence.
%> 4. adaptive: Training is performed as usual to initialize, then both taps 
%> and the update step are also updated over the whole sequence.
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
        %> Operation mode {'training' | 'equalization' | 'semiadaptive' | 'adaptive'}
        operation = 'equalization';
        %> Training type mode {'blind' | 'dataAided'}
        trainingType   = 'blind';
        %> N-by-2 training symbols matrix for dataAided mode.
        trainingSequences;
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
            obj.checkSettings();
        end
        
        %> @brief Main routine
        function [out,outNss] = traverse(obj, in)
            switch obj.operation
                %difference between training and equalization mode sorted
                %out in poldemux_cr_qam_v4_fast
                case 'training'
                    [out] = obj.train_equalizer(in);
                    outNss = in;
                case 'equalization'
                    [out,outNss] = obj.poldemux_cr_qam_v4_fast(in);
                case 'semiadaptive'
                    obj.train_equalizer(in);
                    [out] = obj.poldemux_cr_qam_v4_medium(in);
                    outNss = in;
                case 'adaptive'
                    obj.train_equalizer(in);
                    [out] = obj.poldemux_cr_qam_v4_slow(in);
                    outNss = in;
                otherwise
            end
        end
        
        %> @brief Check user settings
        %>
        %> There are many options with this function, and it's easy to get
        %> confused.  This checks for some more common mistakes and displays
        %> warnings when they arise
        function checkSettings(obj)
            
            %Suggest they don't use CMA for non-PSK
            if numel(obj.R>1)&&strcmpi(obj.type, 'cma')
                robolog('CMA gives worse performance than MMA when the constellation points have more than 1 radius', 'WRN')
            end
            
            %Make sure tap orthogonalization and cma/mma crossover, if
            %applicable, happen at a reasonable time
            if obj.cma_preconv >= obj.equalizer_conv
                %They have a multilevel signal, and want to use MMA
                if strcmpi(obj.type, 'mma')
                    if strcmpi(obj.operation, 'equalization')
                        %MMA will never be used
                        robolog('When cma_preconv >= equalizer_conv, only CMA is used, but you have selected MMA', 'WRN')
                        robolog('Increase equalizer_conv to run MMA', 'WRN')
                    else
                        %MMA will be used, but only after training
                        robolog('Equalizer taps unlikely to fully converge during training', 'WRN')
                        robolog('Increase equalizer_conv to run MMA during training', 'WRN')
                        if obj.h_ortho
                            robolog('Also to give taps time to adjust after forced orthogonalization', 'WRN')
                        end
                    end
                elseif obj.h_ortho
                    %They have a PSK signal, but may still run into issues
                    %due to forced orthogonalization
                    robolog('Better performance expected when equalizer_conv > cma_preconv', 'WRN')
                    robolog('This gives taps time to adjust after forced orthogonalization', 'WRN')
                end
            end
            
            %Sometimes people confuse number of iterations and number of
            %taps
            if obj.iter>10
                robolog('Many iterations requested - performance improvement unlikely for iter>5', 'WRN');
            end
        end
        
        %> @brief Initialize object
        %>
        %> Set filter taps and check user-specified parameter values.
        function initialize(obj)
            % Initialization            
                       
            obj.constellation = obj.constellation/max(abs(obj.constellation));
            
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
        
        function [out1] = train_equalizer(obj,in)
            
           % Amplitude normalization to 1 per polarization.      
            in = in.fun1(@(x)x/max(abs(x)));
            
           % Defining training parameters:
            L = fix((obj.equalizer_conv-obj.taps)/in.Nss+1); % Length of the output (1 sample/symbol) of the training section
            
            if L*in.Nss>in.L
                robolog('The number of samples to be used in the training can not be larger than signal size.','ERR')
            end
            
            switch obj.trainingType
                case 'dataAided'
                    if obj.equalizer_conv>length(obj.trainingSequences)
                        robolog('The number of samples specified for dataAided training can not be larger than the training sequence length size.','ERR')
                    end
                    trainTrace = obj.trainingSequences(fix(obj.taps/in.Nss/2+1):fix(obj.taps/in.Nss/2+1)+L-1,:);
                    trainTrace(:,1) = trainTrace(:,1)/max(abs(trainTrace(:,1)));
                    trainTrace(:,2) = trainTrace(:,2)/max(abs(trainTrace(:,2)));
                    R2 = abs(trainTrace).^2; 
                    flagTrain = 1;
                case 'blind'
                    % Define radius values to be used in MMA training mode:
                    mma = numel(obj.R)>1; % If the constellation has multiple radius values, use MMA.
                    R2 = obj.R'.^2;       % Vector with radius^2 values.
                    
                    if size(R2, 2) > 1    % In case of CMA pre-convergence of MM signals, select the constellation's middle size radius to be used as CM reference.
                        i = ones(1, 2)*floor(size(R2,2)/2 + 1);
                    else
                        i = [1 1];
                    end
                    flagTrain = 0;
                otherwise
                    robolog('Equalizer training type should be "blind" or "dataAided".','ERR')
            end
            
            E_hat = nan(L,2);
            errsq = nan(L+1,2);
            E_Nss = zeros(size(in.E));
            
            % Equalizer training section:
            for iter_k=1:obj.iter
                robolog('Equalizer training iteration #%d','NFO', iter_k)
                temp = (1:obj.taps); % modified for speed
                temp1 = in.Nss;      % modified for speed
                fieldtemp = in.E;    % modified for speed
                for n=1:L
                    progress(n, L);
                    idx = temp+(n-1)*temp1; % Selects the window of samples to equalize
                    field = fieldtemp(idx,:);    % modified for speed
                    E_tmp(:,1) = sum([obj.hxx obj.hxy].*field,2); % Faster than matrix multiplication
                    E_tmp(:,2) = sum([obj.hyx obj.hyy].*field,2);
                    
                    E_hat(n,:) = sum(E_tmp,1); % Equalized output
                    
                    A = abs(E_hat(n,:));       % X
                    
                    if flagTrain % dataAided
                        errsq(n,:) = R2(n,:)-A.^2;
                    else % blind
                        if n>obj.cma_preconv || iter_k > 1
                            if mma, [~,i] = min(ipdm(obj.R,A')); end % Radius choice for MMA taps adaptation
                        end
                        errsq(n,:) = R2(i)-A.^2; % Calculates the square error accordind to the CMA|MMA rules.
                    end
                                                  
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
                    
                    if n==obj.cma_preconv && obj.h_ortho && iter_k== 1
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
            
            out1 = signal_interface(E_hat, struct('Fs', in.Rs, 'Rs', in.Rs, 'P', in.P, 'Fc', in.Fc));
            
            if obj.draw
                plotConv(obj);
            end
        end
        
        %> @brief Fast equalization routine
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
            
           % Amplitude normalization to 1 per polarization.      
            in = in.fun1(@(x)x/max(abs(x)));
            
            % Defining training parameters:
            L = fix((obj.equalizer_conv-obj.taps)/in.Nss+1); % Length of the output (1 sample/symbol) of the training section
            
            if L*in.Nss>in.L
                robolog('The number of samples to be used in the training can not be larger than signal size.','ERR')
            end
            
            switch obj.trainingType
                case 'dataAided'
                    if obj.equalizer_conv>length(obj.trainingSequences)
                        robolog('The number of samples specified for dataAided training can not be larger than the training sequence length size.','ERR')
                    end
                    trainTrace = obj.trainingSequences(fix(obj.taps/in.Nss/2+1):fix(obj.taps/in.Nss/2+1)+L-1,:);
                    trainTrace(:,1) = trainTrace(:,1)/max(abs(trainTrace(:,1)));
                    trainTrace(:,2) = trainTrace(:,2)/max(abs(trainTrace(:,2)));
                    R2 = abs(trainTrace).^2;
                    flagTrain = 1;
                case 'blind'
                    % Define radius values to be used in MMA training mode:
                    mma = numel(obj.R)>1; % If the constellation has multiple radius values, use MMA.
                    R2 = obj.R'.^2;       % Vector with radius^2 values.
                    
                    if size(R2, 2) > 1    % In case of CMA pre-convergence of MM signals, select the constellation's middle size radius to be used as CM reference.
                        i = ones(1, 2)*floor(size(R2,2)/2 + 1);
                    else
                        i = [1 1];
                    end
                    flagTrain = 0;
                otherwise
                    robolog('Equalizer training type should be "blind" or "dataAided".','ERR')
            end
            
            E_hat = nan(L,2);
            errsq = nan(L+1,2);
            E_Nss = zeros(size(in.E));
            
            % Equalizer training section:
            for iter_k=1:obj.iter
                robolog('Equalizer training iteration #%d...   ','NFO', iter_k)
                temp = (1:obj.taps); % modified for speed
                temp1 = in.Nss;      % modified for speed
                fieldtemp = in.E;    % modified for speed
                for n=1:L
                    progress(n, L);
                    idx = temp+(n-1)*temp1; % Selects the window of samples to equalize
                    field = fieldtemp(idx,:);    % modified for speed
                    E_tmp(:,1) = sum([obj.hxx obj.hxy].*field,2); % Faster than matrix multiplication
                    E_tmp(:,2) = sum([obj.hyx obj.hyy].*field,2);
                    
                    E_hat(n,:) = sum(E_tmp,1); % Equalized output
                    
                    A = abs(E_hat(n,:));       % X
                    
                    if flagTrain % dataAided
                        errsq(n,:) = R2(n,:)-A.^2;
                    else % blind
                        if n>obj.cma_preconv || iter_k > 1
                            if mma, [~,i] = min(ipdm(obj.R,A')); end % Radius choice for MMA taps adaptation
                        end
                        errsq(n,:) = R2(i)-A.^2; % Calculates the square error accordind to the CMA|MMA rules.
                    end
                    
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
                    
                    if n==obj.cma_preconv && obj.h_ortho && iter_k== 1
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
            
            robolog('Equalization started','NFO')
            if ~strcmp(obj.operation, 'training')
                temp = (1:obj.taps);        % modified for speed
                temp1 = in.Nss;             % modified for speed
                temp2 = [obj.hxx obj.hxy];  % modified for speed
                temp3 = [obj.hyx obj.hyy];  % modified for speed
                fieldtemp = in.E;           % modified for speed
                for n=1:L
                    progress(n, L);
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
        
        %> @brief Medium-fast equalization routine
        %>
        %> Equalizer taps are applied WITH further adaptation to the
        %> rest of the sequence.  Tap update step size remains constant for
        %> the whole sequence.
        %>
        %>
        %> @param in input signal
        %> @retval out1 equalized output at 1 sample per symbol
        function [out1] = poldemux_cr_qam_v4_medium(obj,in)
            
           % Amplitude normalization to 1 per polarization.      
            in = in.fun1(@(x)x/max(abs(x)));
            
            % Defining training parameters:
            L = fix((in.L-obj.taps)/in.Nss+1); % Length of the output (1 sample/symbol) of the training section
            
            if L*in.Nss>in.L
                robolog('The number of samples to be used in the training can not be larger than signal size.','ERR')
            end
            
            switch obj.trainingType
                case 'dataAided'
                    if obj.equalizer_conv>length(obj.trainingSequences)
                        robolog('The number of samples specified for dataAided training can not be larger than the training sequence length size.','ERR')
                    end
                    trainTrace = obj.trainingSequences(fix(obj.taps/in.Nss/2+1):fix(obj.taps/in.Nss/2+1)+L-1,:);
                    trainTrace(:,1) = trainTrace(:,1)/max(abs(trainTrace(:,1)));
                    trainTrace(:,2) = trainTrace(:,2)/max(abs(trainTrace(:,2)));
                    R2 = abs(trainTrace).^2; 
                    flagTrain = 1;
                case 'blind'
                    % Define radius values to be used in MMA training mode:
                    mma = numel(obj.R)>1; % If the constellation has multiple radius values, use MMA.
                    R2 = obj.R'.^2;       % Vector with radius^2 values.
                    
                    if size(R2, 2) > 1    % In case of CMA pre-convergence of MM signals, select the constellation's middle size radius to be used as CM reference.
                        i = ones(1, 2)*floor(size(R2,2)/2 + 1);
                    else
                        i = [1 1];
                    end
                    flagTrain = 0;
                otherwise
                    robolog('Equalizer training type should be "blind" or "dataAided".','ERR')
            end
                        
            % Filtering section:
            E_hat_out = nan(L,2);
            
            robolog('Equalization started','NFO')
            %store values locally for speed
            temp = (1:obj.taps);
            temp1 = in.Nss;
            hxxtemp = obj.hxx;
            hxytemp = obj.hxy;
            hyxtemp = obj.hyx;
            hyytemp = obj.hyy;
            fieldtemp = in.E;
            mutemp = obj.mu;
            errsq2 = nan(L+1,2);
            for n=1:L
                progress(n, L);
                idx = temp+(n-1)*temp1;     % Selects the window of samples to equalize
                field = fieldtemp(idx,:);   % modified for speed
                E_tmp(:,1) = sum([hxxtemp hxytemp].*field,2); % Faster than matrix multiplication
                E_tmp(:,2) = sum([hyxtemp hyytemp].*field,2);
                E_hat_out(n,:) = sum(E_tmp,1); % Equalized output
                
                %calculate error
                A = abs(E_hat_out(n,:));       % X
                if flagTrain % dataAided
                    errsq2(n,:) = R2(n,:)-A.^2;
                else % blind
                    if mma, [~,i] = min(ipdm(obj.R,A')); end % Radius choice for MMA taps adaptation
                    errsq2(n,:) = R2(i)-A.^2; % Calculates the square error accordind to the CMA|MMA rules.
                end
                e_xx = errsq2(n,1);
                e_yx = errsq2(n,2);
                e_xy = errsq2(n,1);
                e_yy = errsq2(n,2);
                
                % Update the equalizer taps:
                hxxtemp = hxxtemp + mutemp(1)*e_xx*E_hat_out(n,1)*conj(fieldtemp(idx,1));
                hyxtemp = hyxtemp + mutemp(2)*e_yx*E_hat_out(n,2)*conj(fieldtemp(idx,1));
                hxytemp = hxytemp + mutemp(3)*e_xy*E_hat_out(n,1)*conj(fieldtemp(idx,2));
                hyytemp = hyytemp + mutemp(4)*e_yy*E_hat_out(n,2)*conj(fieldtemp(idx,2));
                
            end
            robolog('Equalization completed.')
            robolog('Equalizer MSE = %.6f.', mean(mean(errsq2(1:end-1,:))))
            
            out1 = in.set('E', E_hat_out, 'Fs', in.Rs);
            
            %save taps and step size
            obj.hxx = hxxtemp;
            obj.hxy = hxytemp;
            obj.hyx = hyxtemp;
            obj.hyy = hyytemp;
            obj.mu = mutemp;
            
            %save & draw convergence
            obj.results.errsq = errsq2;
            if obj.draw
                plotConv(obj);
            end
        end
        
        %> @brief Slow equalization routine
        %>
        %> Equalizer taps are applied WITH further adaptation to the
        %> rest of the sequence.  Tap update step size is adapted at each
        %> step.
        %>
        %> @param in input signal
        %> @retval out1 equalized output at 1 sample per symbol
        function [out1] = poldemux_cr_qam_v4_slow(obj,in)
            
           % Amplitude normalization to 1 per polarization.      
           in = in.fun1(@(x)x/max(abs(x)));
            
           % Defining training parameters:
           L = fix((in.L-obj.taps)/in.Nss+1); % Length of the output (1 sample/symbol) of the training section
           
           if L*in.Nss>in.L
               robolog('The number of samples to be used in the training can not be larger than signal size.','ERR')
           end
           
           switch obj.trainingType
               case 'dataAided'
                   if obj.equalizer_conv>length(obj.trainingSequences)
                       robolog('The number of samples specified for dataAided training can not be larger than the training sequence length size.','ERR')
                   end
                   trainTrace = obj.trainingSequences(fix(obj.taps/in.Nss/2+1):fix(obj.taps/in.Nss/2+1)+L-1,:);
                   trainTrace(:,1) = trainTrace(:,1)/max(abs(trainTrace(:,1)));
                   trainTrace(:,2) = trainTrace(:,2)/max(abs(trainTrace(:,2)));
                   R2 = abs(trainTrace).^2;
                   flagTrain = 1;
               case 'blind'
                   % Define radius values to be used in MMA training mode:
                   mma = numel(obj.R)>1; % If the constellation has multiple radius values, use MMA.
                   R2 = obj.R'.^2;       % Vector with radius^2 values.
                   
                   if size(R2, 2) > 1    % In case of CMA pre-convergence of MM signals, select the constellation's middle size radius to be used as CM reference.
                       i = ones(1, 2)*floor(size(R2,2)/2 + 1);
                   else
                       i = [1 1];
                   end
                   flagTrain = 0;
               otherwise
                   robolog('Equalizer training type should be "blind" or "dataAided".','ERR')
           end
                        
            % Filtering section:
            E_hat_out = nan(L,2);
            
            robolog('Equalization started','NFO')
            %store values locally for speed
            temp = (1:obj.taps);
            temp1 = in.Nss;
            hxxtemp = obj.hxx;
            hxytemp = obj.hxy;
            hyxtemp = obj.hyx;
            hyytemp = obj.hyy;
            fieldtemp = in.E;
            mutemp = obj.mu;
            errsq2 = nan(L+1,2);
            for n=1:L
                progress(n, L);
                idx = temp+(n-1)*temp1;     % Selects the window of samples to equalize
                field = fieldtemp(idx,:);   % modified for speed
                E_tmp(:,1) = sum([hxxtemp hxytemp].*field,2); % Faster than matrix multiplication
                E_tmp(:,2) = sum([hyxtemp hyytemp].*field,2);
                E_hat_out(n,:) = sum(E_tmp,1); % Equalized output
                
                %calculate error
                A = abs(E_hat_out(n,:));       % X
                if flagTrain % dataAided
                    errsq2(n,:) = R2(n,:)-A.^2;
                else % blind
                    if mma, [~,i] = min(ipdm(obj.R,A')); end % Radius choice for MMA taps adaptation
                    errsq2(n,:) = R2(i)-A.^2; % Calculates the square error accordind to the CMA|MMA rules.
                end
                e_xx = errsq2(n,1);
                e_yx = errsq2(n,2);
                e_xy = errsq2(n,1);
                e_yy = errsq2(n,2);
                
                % Update the equalizer taps:
                hxxtemp = hxxtemp + mutemp(1)*e_xx*E_hat_out(n,1)*conj(fieldtemp(idx,1));
                hyxtemp = hyxtemp + mutemp(2)*e_yx*E_hat_out(n,2)*conj(fieldtemp(idx,1));
                hxytemp = hxytemp + mutemp(3)*e_xy*E_hat_out(n,1)*conj(fieldtemp(idx,2));
                hyytemp = hyytemp + mutemp(4)*e_yy*E_hat_out(n,2)*conj(fieldtemp(idx,2));
                
                % Update the equalizer step size:
                if n==1
                    mutemp(1)=mutemp(1)/(1+mutemp(1)*(abs(e_xx)^2));
                    mutemp(2)= mutemp(2)/(1+mutemp(2)*(abs(e_yy)^2));
                elseif ~((sign(real(e_xx))==sign(real(errsq2(n-1, 1)))) && (sign(imag(e_xx))==sign(imag(errsq2(n-1, 1)))))
                    mutemp(1)=mutemp(1)/(1+mutemp(1)*(abs(e_xx)^2));
                    if ~((sign(real(e_yy))==sign(real(errsq2(n-1, 2)))) && (sign(imag(e_yy))==sign(imag(errsq2(n-1, 1)))))
                        mutemp(2)= mutemp(2)/(1+mutemp(2)*(abs(e_yy)^2));
                    end
                end
                mutemp(3) = mutemp(1);
                mutemp(4) = mutemp(2);
                
            end
            robolog('Equalization completed.')
            robolog('Equalizer MSE = %.6f.', mean(mean(errsq2(1:end-1,:))))
            
            out1 = in.set('E', E_hat_out, 'Fs', in.Rs);
            
            %save taps and step size
            obj.hxx = hxxtemp;
            obj.hxy = hxytemp;
            obj.hyx = hyxtemp;
            obj.hyy = hyytemp;
            obj.mu = mutemp;
            
            %save & draw convergence
            obj.results.errsq = errsq2;
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
        function varargout = plotTaps(obj)
            f = figure('Name', 'RDE taps');
            subplot(2,2,1); plot(cplx2mat(obj.hxx)); title('h_{xx}');
            subplot(2,2,2); plot(cplx2mat(obj.hxy)); title('h_{xy}');
            subplot(2,2,3); plot(cplx2mat(obj.hyx)); title('h_{yx}');
            subplot(2,2,4); plot(cplx2mat(obj.hyy)); title('h_{yy}');
            if nargout>0
                varargout{1} = f;
            end
        end
        
    end
end