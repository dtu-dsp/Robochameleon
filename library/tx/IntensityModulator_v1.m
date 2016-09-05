%> @file IntensityModulator_v1.m
%> @brief Linear or Mach-Zehnder intensity modulator
%>
%> @class IntensityModulator_v1
%> @brief Linear or Mach-Zehnder intensity modulator
%>
%> Takes 2 signal_interfaces, applies modulation from signal interface 1 (drive)
%> to signal interface 2 (laser).  Runs in linear (ideal, non-physical) or
%> mach-zehnder mode.  Extinction ratio and insertion loss can be specified.
%> Insertion loss is excess insertion loss from fiber coupling, splitters,
%> etc. (i.e. the loss we'd see biasing at a maximum and with no drive
%> signal). Drive-signal related loss is  calculated by the object and stored 
%> in the results structure as inherentLoss.
%>
%> @ingroup physModels
%>
%>
%> __Example:__
%> @code
%>   param.laser.Power = pwr(150, {14, 'dBm'});
%>   param.laser.linewidth = 100;
%>   param.laser.Fs = 160e9;
%>   param.laser.Rs = 1e9;
%>   param.laser.Fc = const.c/1550*1e-9;
%>   param.laser.Lnoise = 2^8;
%>   param.im.Vpi = 6;
%>   param.im.loss = 1;
%>   param.drive.Fs = 160e9;
%>   param.drive.Rs = 1e9;
%>   param.drive.Fc = 0;
%>
%>   %% Linear region MZM
%>   param.im.mode = 'MZM';
%>   param.im.Vbias = -3;
%>   driveAmp = 0.5/2*param.im.Vpi;
%>
%>   laser = Laser_v1(param.laser);
%>   laserSig = laser.traverse();
%>
%>   t = genTimeAxisSig(laserSig);
%>   driveField = driveAmp*sin(2*pi*param.drive.Rs*t);
%>   driveSig = signal_interface(driveField, param.drive);
%>   driveSig = driveSig.set('P', pwr(30, driveSig.P.Ptot));
%>   im = IntensityModulator_v1(param.im);
%>
%>   laserModulated = im.traverse(driveSig, laserSig);
%> @endcode
%>
%> __References:__
%>
%> * [1] Seimetz, High-order modulation for optical fiber transmission
%>
%> @author Molly Piels
%> @author Simone Gaiarin
%>
%> @version 1
classdef IntensityModulator_v1 < unit
    
    properties
        %> Half wave voltage [V]
        Vpi = 5;
        % Bias voltage [V]
        Vbias;
        %> Extinction ratio [dB]
        extinctionRatio = inf;
        %> Operation mode
        mode = 'MZM';       %'linear' (slope = 1/Vpi), 'MZM' (Mach zehnder)
        %> Insertion loss (excess) [dB]
        loss = 0;       %dB
        %> Number of inputs
        nInputs = 2;
        %> Number of outputs
        nOutputs = 1;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type IntensityModulator_v1.
        %>
        %> @param param.Vpi             Half-wave voltage [V]. 
        %> @param param.Vbias           Voltage used to set the working region of the modulator [Default: -Vpi/2]
        %> @param param.mode            Operation mode. Possible values 'linear' (slope = 1/Vpi), 'MZM' (Mach zehnder)
        %> @param param.loss            Loss [dB].
        %> @param param.extinctionRatio Extinction ratio ER = Pmax/Pmin [dB].
        function obj = IntensityModulator_v1(param)
            obj.setparams(param);
            if isempty(obj.Vbias)
                obj.Vbias = -1/2*obj.Vpi; % Bias on quadrature point (non inverting) by default
            end
        end
        
        %> @brief Traverse function
        %>
        %> Takes 2 signal_interfaces, applies modulation from signal interface 1 (drive)
        %> to signal interface 2 (laser).
        %>
        %> @param param.drive             Modulating signal (real, single column).
        %> @param param.laser             Laser (single polarization).
        function modulatedLaser = traverse(obj, drive, laser)
            if laser.N > 1
                robolog('The laser can have only one polarization.', 'ERR');
            end
            if drive.N > 1 || ~isreal(drive.get)
                robolog('The modulating signal must have a single real component.', 'ERR');
            end
            switch obj.mode
                case 'linear'
                    eff=1/obj.Vpi;
                    modulatingSig=sqrt(((drive.get)-min(drive.get))/obj.Vpi);
                    modulatedLaser=laser.fun1(@(x) x.*modulatingSig);
                    modulatedLaser = modulatedLaser*(1-10^(-obj.extinctionRatio/20))+laser*(10^(-obj.extinctionRatio/20));
                case 'MZM'
                    eff=pi/(2*obj.Vpi);     %for noise
                    phi = pi*(drive.get + obj.Vbias)/obj.Vpi; % Induced phase shift
                    modulatingSig = cos(phi/2);
                    modulatedLaser=laser.fun1(@(x) x.*modulatingSig);
                    modulatedLaser = modulatedLaser*(1-10^(-obj.extinctionRatio/20))+laser*(10^(-obj.extinctionRatio/20));
                otherwise
                    robolog('Unsupported intensity modulation type', 'ERR');
            end

            %Input-referenced powers (signal, noise)
            Psig=laser.P.Ps('mW');
            Pn=eff*drive.P.Pn('mW')+laser.P.Pn('mW');
            SNR_out=10*log10(Psig/Pn);
            %set power out
            modulatedLaser = modulatedLaser.set('P', pwr(SNR_out, modulatedLaser.P.Ptot - obj.loss));
            % Copy Rs to laser if defined in drive signal
            if ~isnan(drive.Rs)
                modulatedLaser = modulatedLaser.set('Rs', drive.Rs);
            end
            
            %power loss due to incomplete drive voltage swing, finite ER, etc.
            obj.results.inherentLoss =laser.P.Ptot-modulatedLaser.P.Ptot;
        end
    end
end

