%> @file IQ_v1.m
%> @brief IQ modulator model
%> 
%> @class IQ_v1
%> @brief  IQ modulator model
%>
%> Takes 5 signal_interfaces (4 with data and a laser) and puts it in to one
%> with 2 complex columns plus phase noise and carrier frequency of the laser
%> If 'mode' is set to 'complex', it takes 3 signals (2 with the complex
%> data and the laser)
%> If 'mode' is set to 'single', it takes 2 signals (1 with 2 complex
%> colums and the laser)
%>
%> @author Miguel Iglesias
classdef IQ_v1 < unit
    
    properties
        nInputs=5;
        nOutputs=1;
        
        Vamp;
        Vb;
        Vpi;
        IQphase_x;
        IQphase_y;
        IQgain_imbalance_x;
        IQgain_imbalance_y;
        f_off;
        
    end
    
    methods
        function obj = IQ_v1(param)
            obj.Vamp = paramdefault(param, 'Vamp', 1*ones(4,1));
            obj.Vb = paramdefault(param, 'Vb',  5*ones(4,1));
            obj.Vpi =  paramdefault(param, 'Vpi',  5*ones(4,1));
            obj.IQphase_x = paramdefault(param,'IQphase_x', pi/2);
            obj.IQphase_y = paramdefault(param,'IQphase_y', pi/2);
            obj.IQgain_imbalance_x =  paramdefault(param, 'IQgain_imbalance_x', 0);
            obj.IQgain_imbalance_y =  paramdefault(param, 'IQgain_imbalance_y', 0);
            obj.f_off =  paramdefault(param, 'f_off', 0);
            mode = paramdefault(param, 'mode', 'simple');
            if strcmp(mode, 'complex')
                obj.nInputs = 3;
            elseif strcmp(mode, 'single')
                obj.nInputs = 2;
            end
        end
        
        
        function out = traverse(obj,varargin)
            % Check that there are 4 electrical signals and 1 optical
            % (TODO)
            % Extract params
            Fs = varargin{1}.Fs;
            L = varargin{1}.L;
            switch obj.nInputs
                case 5
                    data = [varargin{1}.get varargin{2}.get varargin{3}.get varargin{4}.get];
                    laser = varargin{5};
                case 3
                    data = [real(varargin{1}.get) imag(varargin{1}.get) real(varargin{2}.get) imag(varargin{2}.get)];
                    laser = varargin{3};
                case 2
                    data = varargin{1}.get;
                    data = [real(data(:,1)) imag(data(:,1)) real(data(:,2)) imag(data(:,2))];
                    laser = varargin{2};
            end
            % Driving signal
            drive = bsxfun(@times,data,obj.Vamp(:).');
            % Tx field
            E_tx = cos(pi/2*bsxfun(@rdivide,bsxfun(@plus,drive,obj.Vb(:).'),obj.Vpi(:).'));
            % Cross talk terms
            x_in_x = 10^(-obj.IQgain_imbalance_x/20);
            x_in_y = 10^(-obj.IQgain_imbalance_y/20);
            % time vector (f?)
            f = (0:L-1)'/Fs;
            % Per polarization power
            P_pol = laser.P.Ptot('W')/2; % Convert dBm to W and divide by 2 to get power per polarization (assuming equal splitting)
            % Put together and add phase noise
            E.x = sqrt(P_pol)*( sum(bsxfun(@times,E_tx(:,1:2), ...
                [x_in_x exp(1i*obj.IQphase_x)]),2) ...
                ) .* exp(1i*2*pi*f*obj.f_off);
            E.x = E.x.*laser.E(1:length(E.x));
            
            E.y = sqrt(P_pol)*( sum(bsxfun(@times,E_tx(:,3:4), ...
                [x_in_y exp(1i*obj.IQphase_y)]),2) ...
                ) .* exp(1i*2*pi*f*obj.f_off);
            E.y = E.y.*laser.E(1:length(E.y));
            
%             drive = struct('x', mat2cplx(drive(:,1:2)), 'y', mat2cplx(drive(:,3:4)));
%             E_tx = struct('x', mat2cplx(E_tx(:,1:2)), 'y', mat2cplx(E_tx(:,3:4)));
%             
            % Generate output signal
            out = signal_interface([E.x E.y], struct('Rs', varargin{1}.Rs, 'Fs', varargin{1}.Fs, 'Fc', laser.Fc, 'P', laser.P));
         end
        
        function ok = check(in)
            ok = 0;
            if length(in) == 2
                if in{1}.N == 1 && in{2}.N == 2
                    if in{1}.Rs == in{2}.Rs && in{2}.Fs == in{2}.Fs
                        ok = 1;
                    else
                        error('Error: Sampling and Symbol rates must coincide')
                    end
                else
                    error('Error: Number of colums for each signal must be 1')
                end
            else
                error('Error: Number of inputs must be 2')
            end
        end
    end
    
end

