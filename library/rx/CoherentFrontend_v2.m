%> @file CoherentFrontend_v2.m
%> @brief coherent front-end with polarization diversity
%>
%> @class CoherentFrontend_v2
%> @brief coherent front-end with polarization diversity
%>
%> @ingroup physModels
%>
%> Coherent front-end module.  
%> Block diagram illustrating dependencies:
%>
%> \image html "CoherentFrontend_v2_blockdiagram.png"
%>
%> Consists of:
%> - local oscillator (Laser_v1)
%> - one PBS (PBS_1xN_v1 for LO)
%> - one optical hybrid (OpticalHybrid_v1)
%> - two  balanced pairs (BalancedPair_v1)
%> - one electrical low pass filter (ElectricalFilter_v1)
%> - one ADC (ResampleSkewJitter_v1)
%> - one quantizer (Quantizer_v1)
%> See relevant class files for model details.
%>
%> The one output is a down-sampled complex baseband signal.
%>
%>
%> __Example__
%> Constructor with minimum parameter set
%> @code
%> frontend = CoherentFrontend_v2(1);
%> @endcode
%>
%> This will construct a dual-pol coherent rx similar to what we have in
%> the lab, however, with a sampling rate equal to the input sampling rate.
%>
%> 
%> __Advanced Example__
%> Coming soon! 
%> @code
%> param.linewidth = 1e6;   %set LO linewidth to 1MHz
%> param.Fc = const.c/1550e-9+5e9;  %set LO wavelength to 1551 nm
%> 
%> param.phase_angle = deg2rad(89);     %1-degree IQ imbalance
%> 
%> param.CMRR = 50;            %common-mode rejection ratio of balanced pairs
%> param.f3dB = 32e9;          %3dB bandwidth of balanced pairs
%> 
%> param.gaussianOrder = 2;
%> param.gaussianBandwidth = 40e9;
%> param.downsamplingRate = 1;     %downsampling not currently functional
%> param.targetENoB = 6;
%> param.bitResolution = 8;
%>
%> CohFrontEndComplex = CoherentFrontend_v2(param);
%> @endcode
%>
%> This will construct a dual-pol coherent rx similar to what we have in
%> the lab, however, with a sampling rate equal to the input sampling rate.
%>
%> @author Molly Piels
%> @version 2
classdef CoherentFrontend_v2 < module
    
    properties
        %> Number of input arguments
        nInputs = 1;
        %> Number of output arguments
        nOutputs = 1;
        
        %> Number of modes
        nModes = 2;
    end
    
    methods
        
        %>  @brief Class constructor
        %>
        %>  Class constructor
        %>
        %> @param param.nModes Number of optical modes in input [integer] [Default: 2]
        %>
        %> Laser_v1
        %> @param param.Power Output power (pwr object). Default: SNR:inf, P: 13 dBm
        %> @param param.linewidth Lorentzian linewidth [Hz] [Default: 100kHz]
        %> @param param.LFLW1GHZ linewidth at 1GHz
        %> @param param.HFLW high-frequency linewidth   [Hz]
        %> @param param.fr relaxation resonance frequency [Hz]
        %> @param param.K Damping factor
        %> @param param.alpha Linewidth enhancement factor [unitless]
        %>
        %> OpticalHybrid_v1
        %> @param param.phase_angle Hybrid phase angle [rad] [Default: pi/2]
        %>
        %> BalancedPair_v1
        %> @param param.R Responsivity [A/W] [Default: 1]
        %> @param param.f3dB electrical 3dB bandwidth [Hz] [Default: 40G]
        %> @param param.Rtherm resistance for thermal noise calculation [ohm] [Default: 50]
        %> @param param.CMRR common-mode rejection ratio [dB][Default: inf]
        %> @param param.T Temperature [K][Default: 290]
        %> @param param.modeAdditionEnabled [flag] [Default: false]
        %>
        %> ElectricalFilter_v1
        %> @param param.gaussianOrder           The order of frequency-domain gaussian filter. Turn OFF = 0 (zero) / Turn ON = any other positive number.
        %> @param param.gaussianBandwidth       Baseband bandwidth of gaussian filter.
        %> @param param.besselOrder             The order of frequency-domain bessel filter for group delay simulation. Turn OFF = 0 (zero) / Turn ON = any other positive integer.
        %> @param param.besselBandwidth         Baseband bandwidth of bessel filter.
        %> @param param.amplitudeImbalance      A vector containing amplitude imbalance for each output. E.g. if outputVoltage = 2, and amplitude imbalance equals to [1 0.9 1.1 0.8], so, the output peak voltage will be 2, 1.8, 2.2, and 1.6 for I1, Q1, I2, and Q2, respectively.
        %> @param param.levelDC                 A vector containing DC levels to be added to each of in-phase and quadrature signals.
        %>
        %> ResampleSkewJitter_v1
        %> @param param.skew           Skew           - A vector with skews: [I1, Q1, I2, Q2, ...]. Normalized by symbol period.
        %> @param param.jitterVariance JitterVariance - The variance of a random walk Jitter.
        %> @param param.clockError     ClockError     - The clock deviance. E.g. 1e-6 means 1 ppm.
        %> @param param.downsamplingRate DownsamplingRate - The downsampling rate. E.g. if the number of samples per symbol of input
        %>                                              is 2 and the downsampling rate is 3, the output will have 0.667 samples per symbol.
        %>
        %> Quantizer_v1
        %> @param param.bitResolution   BitResolution - is the resolution of your quantizer. [Default: 8]
        %> @param param.targetENoB      TargetENoB    - is the ENoB target that you want to achieve adding noise. (Optional)
        %>
        %> @retval CoherentFrontend object
        function obj=CoherentFrontend_v2(varargin)
            if nargin
                param = varargin{1};
                if ~isstruct(param)
                    param = struct('nModes', 2);
                end
                
                % LO parameter conditioning - copy signal parameters to LO
                param.LO = paramDeepCopy('Laser_v1', param);
                param.LO.nInputs = 1;
                % Remove unnecessary fields
                for field={'Fs','Rs','Lnoise'}
                    if isfield(param.LO,field)
                        param.LO = rmfield(param.LO, field);
                    end
                end
                param.LO.Power = paramdefault(param.LO, 'Power', pwr(inf, 13));
                
                %LO split/recombine
                param.LOPBS.nOutputs = param.nModes;
                param.LOPBS.bases = eye(param.LOPBS.nOutputs)/sqrt(param.LOPBS.nOutputs);
                param.LOPBS.Type = 'nDJones';
                param.LOCombiner.nInputs = param.LOPBS.nOutputs;
                param.LOCombiner.type = 'add';
                
                %optical hybrid params
                param.Hybrid = paramDeepCopy('OpticalHybrid_v1',param);
                
                %balanced photodiode parameters
                param.BalancedPairI = paramDeepCopy('BalancedPair_v1', param);
                param.BalancedPairI.modeAdditionEnabled = false;
                param.BalancedPairQ = param.BalancedPairI;
                
                param.IQCombiner.type = 'complexInterleave';
                param.IQCombiner.nInputs = 2;
                
                %ADC params
                param.ELPF = paramDeepCopy('ElectricalFilter_v1',param);
                param.ADCparam = paramDeepCopy('ResampleSkewJitter_v1', param);
                param.location = paramdefault(param, 'location', 'Receiver');
                param.Quantparam = paramDeepCopy('Quantizer_v1', param);
                
                
                %% Components
                branch = BranchSignal_v1(2);
                lo =  Laser_v1(param.LO);
                if param.nModes > 1
                    pbs = PBS_1xN_v1(param.LOPBS);   %for LO
                    combiner = Combiner_v1(param.LOCombiner);
                end
                hybrid = OpticalHybrid_v1(param.Hybrid);
                bpdI = BalancedPair_v1(param.BalancedPairI);
                bpdQ = BalancedPair_v1(param.BalancedPairQ);
                IQcombine = Combiner_v1(param.IQCombiner);
                ElectricalFilter = ElectricalFilter_v1(param.ELPF);
                ADC = ResampleSkewJitter_v1(param.ADCparam);
                Quantizer = Quantizer_v1(param.Quantparam);
                
                %external connections on input
                obj.connectInputs({branch}, 1);
                
                %internal connections
                branch.connectOutputs({hybrid lo}, [1 1]);
                if param.nModes>1
                    lo.connectOutputs(pbs, 1);
                    pbs.connectOutputs(combiner);
                    combiner.connectOutputs(hybrid, 2);
                else
                    lo.connectOutputs(hybrid, 2);
                end
                hybrid.connectOutputs({bpdI bpdI bpdQ bpdQ}, [1 2 1 2]);
                
                %external connections at output
                bpdI.connectOutputs(IQcombine,1);
                bpdQ.connectOutputs(IQcombine,2);
                
                IQcombine.connectOutputs(ElectricalFilter, 1);
                ElectricalFilter.connectOutputs(ADC, 1);
                ADC.connectOutputs(Quantizer, 1);
                
                Quantizer.connectOutputs(obj.outputBuffer, 1);
                
                exportModule(obj);
            end
        end
        
    end
    
end