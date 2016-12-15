%> @file IQ_single_pol_v1.m
%> @brief IQ modulator model
%> 
%> @class IQ_single_pol_v1
%> @brief  IQ modulator model
%>
%> Takes 3 signal_interfaces (2 with data and a laser) and puts it in to one
%> with 1 complex column plus phase noise and carrier frequency of the laser
%> If 'mode' is set to 'simple', it takes 3 signals (2 with the real
%> data and the laser)
%> If 'mode' is set to 'complex', it takes 2 signals (1 with a complex
%> colum and the other with laser)
%>
%> @author Santiago Echeverri
classdef IQ_single_pol_v1 < unit
    
    properties
        nInputs=3;
        nOutputs=1;
        IQgain_imbalance;
        Vamp;
        Vb;
        Vpi;
        IQphase;
        f_off;
        
    end
    
    methods
        function obj = IQ_single_pol_v1(param)
%             obj.Vamp = paramdefault(param, 'Vamp', 1*ones(2,1));
            obj.Vamp = paramdefault(param, 'Vamp', 1*ones(2,1));
            obj.Vb = paramdefault(param, 'Vb',  5*ones(2,1));
            obj.Vpi =  paramdefault(param, 'Vpi',  5*ones(2,1));
            obj.IQphase = paramdefault(param,'IQphase', pi/2);
            obj.IQgain_imbalance =  paramdefault(param, 'IQgain_imbalance', 0);
            obj.f_off =  paramdefault(param, 'f_off', 0);
            mode = paramdefault(param, 'mode', 'simple');
            if strcmp(mode, 'simple')
                obj.nInputs = 3;
            elseif strcmp(mode, 'complex')
                obj.nInputs = 2;
            end
        end
        function out = traverse(obj,varargin)
            % Extract params
            Fs = varargin{1}.Fs;
            L = varargin{1}.L;
            switch obj.nInputs
                case 3
                    data = [varargin{1}.get varargin{2}.get];
                    laser = varargin{3};
                case 2
                    data = varargin{1}.get;
                    data = [real(data(:,1)) imag(data(:,1))];
                    laser = varargin{2};
            end
            % Driving signal
            drive = bsxfun(@times,data,obj.Vamp(:).');
            % Tx field
            E_tx = cos(pi/2*bsxfun(@rdivide,bsxfun(@plus,drive,obj.Vb(:).'),obj.Vpi(:).'));
            % Cross talk terms
            x_in_x = 10^(-obj.IQgain_imbalance/20);
            % time vector (f?)
            f = (0:L-1)'/Fs;
            % Per polarization power
            P_pol = laser.P.Ptot('W'); % Convert dBm to W  to get power.
            % Put together and add phase noise
            E = sqrt(P_pol)*( sum(bsxfun(@times,E_tx(:,1:2), ...
                [x_in_x exp(1i*obj.IQphase)]),2) ...
                ) .* exp(1i*2*pi*f*obj.f_off);
            E = E.*laser.E(1:length(E));
%             E = data(:,1) + 1j.*data(:,2);
            % Generate output signal
            out = signal_interface(E , struct('Rs', varargin{1}.Rs, 'Fs', varargin{1}.Fs, 'Fc', laser.Fc, 'P', laser.P));
         end
        
    end
    
end

