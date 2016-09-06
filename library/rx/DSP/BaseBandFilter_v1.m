%> @file BaseBandFilter_v1.m
%> @brief This class implements a baseband filter
%>
%> @ingroup stableDSP
%>
%> @class BaseBandFilter_v1
%> @brief This class implements a baseband filter
%> 
%> The filter is based on the WaveShaper model. There is also an
%> option to used a "ideal" rectangular filter model.
%>
%> __Example:__
%> @code
%> param.bandwidth = 28e9;             % Cutoff bandwidth
%> param.type      = 'Gaussian';       % Type of filter
%> filter = BaseBandFilter_v2(param);
%> @endcode
%>
%> @author Edson Porto da Silva
%> @author Simone Gaiarin
classdef BaseBandFilter_v1 < unit
      
    properties
        %> Filter type
        type = 'ideal';
        %> Cutoff bandwidth
        bandwidth;
        %> Number of inputs
        nInputs = 1;
        %> Number of outputs
        nOutputs = 1;
    end
    
    methods
        %> @brief Class constructor
        %>
        %> Constructs an object of type BaseBandFilter_v2 using the specified filter type
        %> and cutoff bandwidth.
        %>
        %> @param param.type          Filter type. Possible values = {'gaussian', 'rectangular', 'ideal'}.
        %>                            [Default: ideal]
        %> @param param.bandwidth     Cutoff bandwidth [Hz]. 3dB bandwidth? Add more detailed explanation.
        function obj = BaseBandFilter_v1(param)
            obj.setparams(param);
        end
        
        %> @brief Filter the input signal with the filter
        %>
        %> @param Ein    The signal_interface of the input signal that will be filtered.
        %>
        %> @retval out  The signal_interface of the signal which has been filtered with the specified filter.
        function Eout = traverse(obj, Ein)
            
            %> @brief Main filter
            
            %> Frequency domain filtering:
            f = linspace(-1/2,1/2,Ein.L);  %> Define frequency range
            
            switch lower(obj.type)
                   %> Extracted from WaveShaper Model of Finisar:
                case 'gaussian'
                    filt_sigma = (obj.bandwidth - 3.5e9)/Ein.Fs/2;
                    filt_BW = 1e9/Ein.Fs;
                    %> Extracted from WaveShaper Model of Finisar:
                    %> Frequency domaing filter:
                    Sf  = filt_sigma*sqrt(2*pi)*(erf((filt_BW/2-f)/(filt_sigma*sqrt(2)))-erf((-filt_BW/2-f)/(filt_sigma*sqrt(2))));
                    Sf = Sf/max(abs(Sf));
                    
                case 'rectangular'
                    filt_sigma = 4.2466e9/Ein.Fs;
                    filt_BW = obj.bandwidth/Ein.Fs;
                    %> Extracted from WaveShaper Model of Finisar:
                    %> Frequency domaing filter:
                    Sf  = filt_sigma*sqrt(2*pi)*(erf((filt_BW/2-f)/(filt_sigma*sqrt(2)))-erf((-filt_BW/2-f)/(filt_sigma*sqrt(2))));
                    Sf = Sf/max(abs(Sf));
                    
                case 'ideal'
                    %> Frequency domain ideal filter:
                    filt_BW = obj.bandwidth/Ein.Fs/2;
                    Sf = ones(1,Ein.L);
                    Sf(abs(f)>=filt_BW) = 0;
            end
            
            Sf = [Sf(ceil(length(Sf)/2):end) Sf(1:ceil(length(Sf)/2)-1)].';
            
            % Perform filtering
            % FIXME: fun1 is twice as slow as manual filtering. How to improve?
            Eout = Ein.fun1(@(x) ifft(fft(x).*Sf));
            
            if obj.draw
                figure;
                plot(f*Ein.Fs/1e9,10*log10(Sf),'linewidth',4);
                hold on;
                B3dB = -3*ones(1,length(Sf));
                plot(f*Ein.Fs/1e9,B3dB,'r--','linewidth',4);
                xlabel('Frequency (GHz)');
                ylabel('Att (dB)');
                title(['Baseband Eq. Filter Frequency Response: BW = ' num2str(obj.bandwidth/1e9) ' GHz']);
                legend('Attenuation Response','3dB Cutoff','location','SouthWest');
                ylim([-20 1]);
                xlim([-1.2*obj.bandwidth/1e9 1.2*obj.bandwidth/1e9]);
            end
        end
    end
end
