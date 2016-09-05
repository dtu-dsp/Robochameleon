%> @file IQModulator_v1.m
%> @brief I-Q modulator model

%>@class IQModulator_v1
%>@brief I-Q modulator model
%>
%> @ingroup physModels
%>
%> Basic model of an IQ optical modulator.  In principle, this should work
%> for an arbitrary number of modes.
%>
%> __Observations__
%>
%> 1. Number of inputs-checking is done upon traverse
%>
%> 2. Noise from the electrical drive is not passed through to the output
%>      signal_interface
%>
%> 3. The modulator has unlimited bandwidth
%>
%> 4. By default, the input drive signal is rescaled to an appropriate
%>      value for the given Vpi; this can be disabled
%>
%>
%> __Conventions__
%> * The laser signal_interface is passed last
%>
%>
%> __Example__
%> @code
%>   % The IQ modulator with no input parameters should behave like an
%>   % ideal IQ modulator
%>
%>  drive = createDummySignal();        %2-pol complex drive input
%>
%>  param.laser.Power = pwr(150, {14, 'dBm'});
%>  param.laser.linewidth = 100;
%>  param.laser.Fs = 160e9;
%>  param.laser.Rs = 1e9;
%>  param.laser.Fc = const.c/1550e-9;
%>  param.laser.Lnoise = drive.L;
%>
%>  laser = Laser_v3(param.laser);
%>  laserSig = laser.traverse();
%>
%>   IQ = IQModulator_v1();
%>
%>   sigOut = IQ.traverse(drive, laser);
%> @endcode
%>
%>
%> __Advanced Example__
%> @code
%>   % One can also set any parameters
%>
%>  drive = createDummySignal();        %2-pol complex drive input
%>
%>  param.laser.Power = pwr(150, {14, 'dBm'});
%>  param.laser.linewidth = 100;
%>  param.laser.Fs = 160e9;
%>  param.laser.Rs = 1e9;
%>  param.laser.Fc = const.c/1550e-9;
%>  param.laser.Lnoise = drive.L;
%>
%>  param.IQ.Vpi = 4;                 %all child MZMs have a Vpi of 4 V
%>  param.IQ.Vb = [3.5, 4, 4, 4];     %the first child MZM is biased
%>                                      %incorrecty
%>  IQphase = [deg2rad(80), deg2rad(90)];    %the first polarization has 10
%>                                          %degrees of quadrature error; the second is OK
%>  IQGainImbalance = 0;                 %there is no gain imbalance anywhere
%>
%>  laser = Laser_v3(param.laser);
%>  laserSig = laser.traverse();
%>
%>  IQ = IQModulator_v1(param.IQ);
%>
%>  sigOut = IQ.traverse(drive, laser);
%> @endcode
%>
%>
%>
%> @author Molly Piels
%>
%> @version 1
classdef IQModulator_v1 < unit
    
    properties
        %> Number of inputs
        nInputs = 2;
        %> Number of outputs
        nOutputs = 1;
        %> Bias voltage [V]
        Vb = 4;
        %> Vpi [V]
        Vpi = 4;
        %> I-Q phase angle [rad]
        IQphase = pi/2;
        %> I-Q gain imbalance [dB]
        IQGainImbalance = 0;
        
        %> Force peak drive voltage to a certain value?
        rescaleVdrive = true;
        %> What value should it be forced to?
        Vamp = 1;
    end
    
    properties (Access = private)
        %> Number of output modes
        nModes;
    end
    
    methods (Static)
        
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Constructs an object of type IQModulator_v1
        %>
        %> Most parameters (Vb, Vpi, IQphase, IQGainImbalance)can be passed
        %> as either a scalar or a vector.  If they are passed as a scalar,
        %> the same value is applied to all relevant sub-components.  If
        %> they're passed as vectors, there must be one value for each
        %> subcomponent (4x Vpi's and Vb's and 2x imbalances and phase
        %> angles for a standard dual-pol IQ modulator).  Mixtures of
        %> scalars and vectors are acceptable.
        %>
        %> @param param.Vb          Bias voltage [V]. [Default: Vpi=4]
        %> @param param.Vpi         V pi for child modulators [V] [Default: 4].
        %> @param param.IQphase     IQ phase angle [rad] [Default: pi/2].
        %> @param param.IQGainImbalance     Gain imbalance in I and Q [dB] [ Default: 0].
        %> @param param.rescaleVdrive   Force drive signal to a certain value [boolean] [Default: on]
        %> @param param.Vamp            What drive voltage should be forced to, if rescaling is enabled [V] [Default: 1];
        %>
        %> @retval obj      An instance of the class IQModulator_v1
        function obj = IQModulator_v1(varargin)
            if nargin==1
                obj.setparams(varargin{1});
            elseif nargin ==0
                obj.setparams(1);    %tell user about defaults if enabled
            else
                robolog('Too many input arguments', 'ERR');
            end
        end
        
        %> @brief Applies drive signal to laser
        %>
        %> There is some flexibility in how drive signals are specified.
        %> The following are acceptable:
        %>
        %> 1. A single signal_interface with multiple complex
        %> baseband columns
        %>
        %> 2. Several signal_interface objs with one complex baseband column
        %>  each
        %>
        %> 3. A single signal_interface with an even number of columns, or
        %> an even number of single-column signal_interfaces.
        %>
        %> @param varargin    Drive1, Drive2, ... laser
        %>
        %> @retval out  Modulated laser
        function out = traverse(obj, varargin)
            %Input checking & conditioning
            %  Creates a signal_interface called driveSignals that has 1
            %  real column for each drive and one called laser for the
            %  laser
            
            
            % Handling Inputs 
            
            nDriveSignals = nargin-2;       %number of signal_interface objects corresponding to drive signals (!= driveSignal.N)
            laser = varargin{nDriveSignals + 1};
            
            
            if isreal(getRaw(varargin{1}))
                %mode = 'real';
                driveSignal = varargin{1};
                for jj = 2:nDriveSignals
                    driveSignal = combine(driveSignal, varargin{jj});
                end
            else
                %mode = 'complex';
                if varargin{1}.N ~= 1
                    p = params(varargin{1});
                    p = rmfield(p, 'P');
                    p = rmfield(p, 'PCol');
                    auxiliary = fun1(varargin{1}, @(x)[real(x) imag(x)]); % This is a problematic signal_interface
                    driveSignal = signal_interface(auxiliary.E, p);
                    clear auxiliary p
                else
                    driveSignal = combine(fun1(varargin{1}, @(x)real(x)), fun1(varargin{1}, @(x)imag(x)));
                    for jj = 2:nDriveSignals
                        tmp = combine(fun1(varargin{jj}, @(x)real(x)), fun1(varargin{jj}, @(x)imag(x)));
                        driveSignal = combine(driveSignal, tmp);
                    end
                    clear tmp;
                end
            end
            obj.nModes = driveSignal.N/2;
            inputRs = varargin{1}.Rs;
            clear varargin
            
            if ~iswhole(obj.nModes)
                robolog('Must have integer number of complex baseband signals', 'ERR');
            end
            obj.checkParamSizes();
            
            % TODO fix this part of algorithm
            % Rescale driving signal
            if obj.rescaleVdrive
                Pdrive = 2*(obj.Vamp)^2;
                driveSignal = set(driveSignal, 'P', pwr(driveSignal.P.SNR, {Pdrive, 'W'}));
            end
            
            p = params(driveSignal);
            
            % Tx field before phase noise loading
            pColImb = p.PCol;
            for jj = 1:obj.nModes
                idx = 2*(jj-1)+1;
                pColImb(idx) = p.PCol(idx)*10^(-obj.IQGainImbalance(jj)/20);
                pColImb(idx+1) = p.PCol(idx+1)*10^(obj.IQGainImbalance(jj)/20);
            end
            
            driveSignal = set(driveSignal, 'PCol', pColImb);
            pBias = rmfield(p, 'PCol');
            pBias.P = pwr(inf, {2*obj.nModes*pwr.meanpwr(obj.Vb), 'W'});
            biasSignal = signal_interface(repmat(obj.Vb, driveSignal.L, 1), pBias);
            driveSignal = driveSignal*diag(1./obj.Vpi);
            biasSignal = biasSignal.getRaw*diag(1./obj.Vpi);
            driveSignal = driveSignal.getRaw+biasSignal;
            clear biasSignal
            driveSignal = cos(pi*driveSignal/2);
            
            % Figure out output signal length
            [lengthOut, idx] = min([laser.L, size(driveSignal,1)]);
            if laser.L ~= size(driveSignal,1)
                if idx == 1
                    robolog('Taking output length from laser', 'NFO')
                else
                    robolog('Taking output length from drive signal', 'NFO')
                end
            end
            
            % Convert to complex w/ phase imbalance and add phase noise
            laserField = laser.get;
            Eout = nan(lengthOut, obj.nModes);
            for jj = 1:obj.nModes
                idx = 2*(jj-1)+1;
                Eout(:, jj) = laserField(1:lengthOut, min(jj, laser.N)).*(driveSignal(1:lengthOut, idx) + driveSignal(1:lengthOut, idx+1)*exp(1i*obj.IQphase(jj)));
            end
            clear driveSignal
            
            paramout = params(laser);
            paramout = rmfield(paramout, 'PCol');
            paramout.Rs = inputRs;
            paramout.P = paramout.P/obj.nModes;
            averagePower = 10^(paramout.P.Ptot/10)*1e-3*pwr.meanpwr(Eout)/mean(pwr.meanpwr(Eout));
            for ii = 1:size(Eout,2)
                paramout.PCol(ii) = pwr(inf, {averagePower(ii), 'W'});
            end
            paramout = rmfield(paramout, 'P');
            out = signal_interface(Eout, paramout);
        end
        
        %> @brief Checks input signals for consistency with model
        %> parameters
        function checkParamSizes(obj)
            if length(obj.Vb) == 1
                obj.Vb = repmat(obj.Vb, 2*obj.nModes, 1);
            elseif length(obj.Vb) ~= 2*obj.nModes
                robolog('Number of specified bias voltages (Vb) must be 1 or match number of child MZMs', 'ERR');
            end
            obj.Vb = obj.Vb(:).';
            if length(obj.Vpi) == 1
                obj.Vpi = repmat(obj.Vpi, 2*obj.nModes, 1);
            elseif length(obj.Vpi) ~= 2*obj.nModes
                robolog('Number of specified pi voltages (Vpi) must be 1 or match number of child MZMs', 'ERR');
            end
            if length(obj.IQphase) == 1
                obj.IQphase = repmat(obj.IQphase, obj.nModes, 1);
            elseif length(obj.IQphase) ~= obj.nModes
                robolog('Number of specified IQ phase angles must be 1 or match number of IQ modulators', 'ERR');
            end
            if length(obj.IQGainImbalance) == 1
                obj.IQGainImbalance = repmat(obj.IQGainImbalance, obj.nModes, 1);
            elseif length(obj.IQGainImbalance) ~= obj.nModes
                robolog('Number of specified IQ gain imbalances must be 1 or match number of IQ modulators', 'ERR');
            end
        end
    end
end
