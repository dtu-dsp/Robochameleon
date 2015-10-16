%>  @file ADC_v1.m
%>  @brief Analog-digital converter model including timebase skew,
%>  inter-channel skew, and random (Gaussian) jitter
%>
%>  @class ADC_v1
%>  @brief Analog-digital converter model
%> 
%>  @ingroup physModels
%>
%>  Analog-digital converter model including timebase skew, inter-channel
%>  skew, and jitter.  Caution: No anti-aliasing filter is used (design and
%>  implement your own).
%>
%>  Example:
%>  Generate a sine wave and re-sample it with jitter and skew
%>  @code
%>  time_normal = linspace(0, 10, 50).';
%>  signal = signal_interface(sin(time_normal), struct('Fs', 800e9, 'Rs', 1, 'Fc', 0, 'P', pwr(inf, 0)));
%>  param=struct('SamplingRate', 80e9, 'TimebaseSkew', 1+1e-5, 'JitterAbsolute', 1e-12);
%>  ADC = ADC_v1(param);
%>  signal_sampled = ADC.traverse(signal);
%>  plot(signal.Ts*(0:signal.L-1), get(signal), signal_sampled.Ts*(0:signal_sampled.L-1), get(signal_sampled), 'o')
%>  xlabel('Time'), ylabel('Amplitude'), legend('Signal', 'Sampled Signal')
%>  @endcode
%>  This will produce an output signal sampled at 80 GS/s.  If the
%>  transmitted baud rate is 32 GBd, the output signal will have an
%>  effective baud rate of 32/(1.00001) GBd = 31.99968 GBd.  The 
%>  labeled baud rate - the one in the output signal Rs field - will be 
%>  32 Gbd.  This example will also have some timing jitter, which appears 
%>  as noise in the generated plot.
%>
%>
%>  @author Molly Piels
%>  @version 2
classdef ADC_v1 < unit
    
    properties
        %>Number of inputs
        nInputs;
        %>Number of outputs
        nOutputs;
        
        %>Output sampling rate (Hz)
        SamplingRate;
        %>Tx clock vs. Rx clock mismatch, with respect to Tx clock (>1 implies Tx clock faster than Rx clock)
        TimebaseSkew;
        %>absolute (Gaussian) jitter standard deviation, in s
        JitterAbsolute;
        %>Inter-channel skew.  Vector of delays, in s.  For single-element signals, this can also be used to add a (fine) absolute delay
        ChannelSkew;
        
    end
    
    methods
        
        %>  @brief Class constructor
        %> 
        %>  Class constructor
        %>
        %>  Example:
        %>  @code
        %>  param=struct('SamplingRate', 80e9, 'TimebaseSkew', 1+1e-5, 'JitterAbsolute', 1e-12);
        %>  ADC = ADC_v1(param);
        %>  @endcode
        %> 
        %> @param param.SamplingRate output sampling rate (Hz)
        %> @param param.TimebaseSkew Tx clock vs. Rx clock mismatch, w.r.t.Tx clock (default 1) (>1 implies Tx clock faster than Rx clock)
        %> @param param.JitterAbsolute Absolute jitter standard deviation (s) (default 0)
        %> @param param.ChannelSkew inter-channel skew.  Vector of delays,in s. (default 0)
        %>
        %> @retval ADC object
        function obj = ADC_v1(param)
           obj.SamplingRate = param.SamplingRate;
           obj.TimebaseSkew = paramdefault(param, 'TimebaseSkew', 1);
           obj.JitterAbsolute = paramdefault(param, 'JitterAbsolute', 0);
           obj.ChannelSkew = paramdefault(param, 'ChannelSkew', nan);
           
           obj.nInputs = paramdefault(param, 'nInputs', 1);
           obj.nOutputs = paramdefault(param, 'nOutputs', 1);
        end
        
        %>  @brief Traverse function
        %>  
        %>  Constructs "impaired" timing basis, then downsamples input signal to it 
        %>  using spline interpolation
        %>
        %> @retval out downsampled signal
        %> @retval results no results
        function varargout = traverse(obj, varargin)
            
            %Combine inputs
            in = Combiner_v1.combine(varargin);            
            
            %skew (want to do this at larger Fs)
            if ~isnan(obj.ChannelSkew)
                if numel(obj.ChannelSkew)~= in.N
                    error('Number of channel skews must correspond to number of elements in input signal')
                end
                Field = get(in);
                fineskew = mod(obj.ChannelSkew*in.Fs, 1)/in.Fs;     % in seconds
                coarseskew = obj.ChannelSkew-fineskew;              % seconds
                coarseskew_samples = round(coarseskew*in.Fs);       % samples
                for jj=1:in.N
                    %coarse
                    ftmp=circshift(Field(:,jj), coarseskew_samples(jj));
                    if coarseskew_samples>0
                        ftmp = ftmp(coarseskew_samples(jj):end);
                    else
                        ftmp = ftmp(1:end+coarseskew_samples(jj));
                    end
                    %fine
                    ftmp=addskew(ftmp,fineskew(jj),in.Fs);
                    Field(1:length(ftmp),jj)=ftmp;
                end
                
                %crop
                in = set(in, Field(1:end-max(abs(coarseskew_samples)), :));
            end
            
            %Ideal new timing basis (old timing basis is 1:1:in.L)
            t_new = 1:in.Fs/obj.SamplingRate:in.L;
            %Impaired new timing basis
            t_new = t_new*obj.TimebaseSkew+obj.JitterAbsolute*in.Fs*randn(1, length(t_new));
            %resample
            res = fun1(in, @(x) interp1(x, t_new.', 'spline', 0));
            res_out=set(res, 'Fs', obj.SamplingRate);
            
            %parse output
            varargout = obj.parse_outputs(res_out);
 
        end
                
        %>  @brief Output conditioner
        %>  Allows arbitrary output number of arguments
        function output=parse_outputs(obj, in)
            if obj.nOutputs >1
                if obj.nOutputs == in.N
                    sig = get(in);
                    for jj=1:obj.nOutputs
                        output{jj}=set(in, 'E', sig(:,jj), 'PCol', in.PCol(jj));
                    end
                else
                    error('Number of outputs must match number of signal components')
                end
            else
                output = {in};
            end
        end
        
    end
    
end

