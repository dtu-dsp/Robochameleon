%> @file CoherentFrontend_single_pol_v1.m
%> @brief coherent front-end with polarization diversity
%>
%> @class CoherentFrontend_single_pol_v1
%> @brief coherent front-end with polarization diversity
%> 
%>  @ingroup physModels
%>
%> Coherent front-end module.  Consists of:
%> - local oscillator (Laser_v1)
%> - optical hybrid (OpticalHybrid_v1)
%> - two  balanced pairs (BalancedPair_v1)  
%> See relevant class files for model details.
%>
%> The two outputs are, in order, I, Q
%>
%> @author Santiago Echeverri
%> @version 1
classdef CoherentFrontend_single_pol_v1 < module
    
    properties
        %> Number of input arguments
        nInputs = 1; 
        %> Number of output arguments
        nOutputs = 2;
    end
    
    methods
        
        %>  @brief Class constructor
        %> 
        %>  Class constructor
        %>
        %>  Example:
        %>  @code
        %>  %% Specify parameters
        %>  % LO has a center frequency 50 MHz above signal, 100kHz linewidth, and 5 dBm output power.
        %>  foffset = 50e6;
        %>  LOparam = struct('Power', pwr(150, {5, 'dBm'}), 'linewidth', 100e3, 'Fc', const.c/signal_wavelength+foffset);
        %>  % Balanced pair(s) have 1A/W, 50dB CMRR, 36 GHz bandwidth
        %>  BPDparam = struct('R', 1, 'CMRR', 50, 'f3dB', 36e9, 'Rtherm', 50);
        %>  %% Rename parameters
        %>  param.LO = LOparam;
        %>  % align local oscillator to 45 degrees at input of PBS
        %>  param.hyb.phase_angle = pi/2;
        %>  %% Construct object
        %>  CohFrontend = CoherentFrontend_single_pol_v1(param)
        %>  @endcode
        %> 
        %> @param param.LO local oscillator parameters
        %> @param param.hyb optical hybrid parameters
        %> @param param.bpd balanced pair parameters
        %>
        %> @retval CoherentFrontend object
        function obj=CoherentFrontend_single_pol_v1(param)
            %% Laser_v1 tweak
            % Force Laser_v1 to work in mode where noise length is
            % dictated by the input signal
            param.LO.nInputs = 1;
            if isfield(param,'draw')
                obj.draw = param.draw;
            end
            % Remove unnecessary fields
            for field={'Fs','Rs','Lnoise'}
                if isfield(param.LO,field)
                    param.LO = rmfield(param.LO, field);
                end
            end
            
            %% Components
            branch = BranchSignal_v1(2);
            lo =  Laser_v1(param.LO);
            hyb = OpticalHybrid_v2(param.hyb); %x-pol
            bpd1 = BalancedPair_v2(param.bpd);
            bpd2 = BalancedPair_v2(param.bpd);

            %external connections on input
            obj.connectInputs({branch}, 1);
            
            %internal connections
            branch.connectOutputs({hyb lo}, [1 1]);
            lo.connectOutputs(hyb, 2);
            hyb.connectOutputs({bpd1 bpd1 bpd2 bpd2}, [1 2 1 2]);
            
            %external connections at output
            bpd1.connectOutputs(obj.outputBuffer,1);
            bpd2.connectOutputs(obj.outputBuffer,2);
            
            exportModule(obj);
        end        
    end
    
end