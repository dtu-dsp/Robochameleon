%> @file getPColFromNumeric_v1.m
%> @brief Construct array of pwr objects from a numeric signal
%>
%> This is a utility function to help in constructing signal_interface
%> objects that have waveform-defined power scaling.  
%>
%>
%> __Example__
%> @code
%> Generate a dummy waveform with a specified peak-peak voltage
%> vpp = 4;
%> testsig = randn(100, 2);
%> testsig(testsig>0) = vpp/2;
%> testsig(testsig<0) = -vpp/2;
%> testsig(:,2) = testsig(:,2)*0.5;
%>
%> %Use function
%> [PCol] = getPColFromNumeric_v1(testsig, [10, 30].');
%> 
%> %Construct signal_interface object using waveform and new PCol
%> sigparams.Fs = 1;
%> sigparams.Rs = 1;
%> sigparams.Fc = 0;
%> sigparams.PCol = PCol;
%> test_signal = signal_interface(testsig, sigparams);
%> 
%> %Check performance
%> preim(test_signal)
%> @endcode
%>
%>
%> @author Molly Piels
%>
%> @see signal_interface
%> @see pwr
%>
%> @version 1

%> @brief Construct array of pwr objects from a numeric signal
%>
%> This is a utility function to help in constructing signal_interface
%> objects that have waveform-defined power scaling.  
%>
%> @param waveform          Array of signal waveforms (each column is an independent signal) [unit]. 
%> @param SNR               Signal-to-noise ratio of output pwr object.  
%>                          Can be passed as an array or scalar value [dB]. [Default: inf]
%> 
%>
%> @retval PCol             Array of pwr objects with power set from
%>                          raw waveform
function [PCol] = getPColFromNumeric_v1(waveform, varargin)

%Input parser
nSignals = size(waveform, 2);
if nargin == 1
    SNR = inf(1, nSignals);
elseif nargin == 2
    SNR = varargin{1};
    if isscalar(SNR)
        SNR = repmat(SNR, 1, nSignals);
    elseif (length(SNR) ~= nSignals)
        robolog('SNR must be scalar or match number of waveforms', 'ERR')
    end
else
    robolog('Too many input arguments', 'ERR')
end

%main calculation
avpow = pwr.meanpwr(waveform);
PCol = pwr(SNR(1), {avpow(1),'W'});
for jj=2:nSignals
    PCol(jj) = pwr(SNR(jj), {avpow(jj),'W'});
end

end
