%> @file CoherentFrontend_v1.m
%> @brief coherent front-end with polarization diversity
%>
%> @class CoherentFrontend_v1
%> @brief coherent front-end with polarization diversity
%> 
%>  @ingroup physModels
%>
%> Coherent front-end module.  Consists of:
%> - local oscillator (Laser_v1)
%> - two PBS (PBS_1xN_v1) 
%> - two optical hybrids (OpticalHybrid_v1)
%> - four  balanced pairs (BalancedPair_v1)  
%> See relevant class files for model details.
%>
%> The four outputs are, in order, I1, Q1, I2, Q2
%> The user can specify PBS parameters, but typically this would be done so
%> that the outputs were Ix, Qx, Iy, Qy.
%> 
%> 
%> Note: PBS_v1 will assign a state of polarization to the LO - make
%> sure it is something that makes sense (45 deg., not TE).  The default
%> should be 45, but if one signal is zero, this may be why. (PBS_v1
%> will also assign a SOP to the input signal if it is unpolarized.
%> Again, you have to check this makes sense).
%> 
%> Relative to a real coherent front end, this implementation has one
%> implementation difference.  There is a splitter on the input that feeds
%> the input signal to the LO.  This is so that the signal length from the
%> LO is the same length as the input signal.
%>
%> @author Molly Piels
%> @version 1
classdef CoherentFrontend_v1 < module
    
    properties
        %> Number of input arguments
        nInputs = 1; 
        %> Number of output arguments
        nOutputs = 4;
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
        %>  % PBS is a standard TE/TM PBS with infinite ER.
        %>  PBSparam = struct('bases', eye(2), 'nOutputs', 2);
        %>  % Balanced pair(s) have 1A/W, 50dB CMRR, 36 GHz bandwidth
        %>  BPDparam = struct('R', 1, 'CMRR', 50, 'f3dB', 36e9, 'Rtherm', 50);
        %>  %% Rename parameters
        %>  param.LO = LOparam;
        %>  % align local oscillator to 45 degrees at input of PBS
        %>  param.LOPBS = catstruct(PBSparam, struct('align_in', [1 1]/sqrt(2)));
        %>  param.sigPBS = PBSparam;
        %>  param.hyb.phase_angle = pi/2;
        %>  param.bpd = BPDparam;
        %>  %% Construct object
        %>  CohFrontend = CoherentFrontend_v1(param)
        %>  @endcode
        %> 
        %> @param param.LO local oscillator parameters
        %> @param param.sigPBS signal PBS paramters
        %> @param param.LOPBS local oscillator PBS paramters
        %> @param param.hyb optical hybrid parameters
        %> @param param.bpd balanced pair parameters
        %>
        %> @retval CoherentFrontend object
        function obj=CoherentFrontend_v1(param)
            %% Laser_v1 tweak
            % Force Laser_v1 to work in mode where noise length is
            % dictated by the input signal
            param.LO.nInputs = 1;
            % Remove unnecessary fields
            for field={'Fs','Rs','Lnoise'}
                if isfield(param.LO,field)
                    param.LO = rmfield(param.LO, field);
                end
            end
            
            %% Components
            branch = BranchSignal_v1(2);
            lo =  Laser_v1(param.LO);
            pbs1 = PBS_1xN_v1(param.sigPBS);   %for signal
            pbs2 = PBS_1xN_v1(param.LOPBS);   %for LO
            hyb1 = OpticalHybrid_v1(param.hyb); %x-pol
            hyb2 = OpticalHybrid_v1(param.hyb); %y-pol
            bpd1 = BalancedPair_v1(param.bpd);
            bpd2 = BalancedPair_v1(param.bpd);
            bpd3 = BalancedPair_v1(param.bpd);
            bpd4 = BalancedPair_v1(param.bpd);

            %external connections on input
            obj.connectInputs({branch}, 1);
            
            %internal connections
            branch.connectOutputs({pbs1 lo}, [1 1]);
            lo.connectOutputs(pbs2, 1);
            pbs1.connectOutputs({hyb1 hyb2}, [1 1]);
            pbs2.connectOutputs({hyb1 hyb2}, [2 2]);
            hyb1.connectOutputs({bpd1 bpd1 bpd2 bpd2}, [1 2 1 2]);
            hyb2.connectOutputs({bpd3 bpd3 bpd4 bpd4}, [1 2 1 2]);
            
            %external connections at output
            bpd1.connectOutputs(obj.outputBuffer,1);
            bpd2.connectOutputs(obj.outputBuffer,2);
            bpd3.connectOutputs(obj.outputBuffer,3);
            bpd4.connectOutputs(obj.outputBuffer,4);
            
            exportModule(obj);
        end
        
    end
    
end