%> @file spectra.m
%> @brief Returns the single-sided amplitude spectrum and plots (optional)
%>
%> @author Miguel Iglesias Olmedo
%> @date 23/11/2012
%> @version

%> @brief Returns the single-sided amplitude spectrum and plots (optional)
%>
%> @param y                 Time domain signal
%> @param Fs                Sampling frequency [Hz]
%> @param plotS             Flag to enable plotting the PSD
%>
%> @retval f            frequency vector [Hz]
%> @retval spectrum     spectrum vector [natural units]
function [ f, spectrum ] = spectra(y, Fs , plotS)

L=length(y);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
%     NFFT = 2^14;
Y = fft(y,NFFT)/L;              % FFT divided by the length to get the power
f = Fs/2*linspace(0,1,NFFT/2+1);% Frequency vector
spectrum=2*abs(Y(1:NFFT/2+1));  % Single-sided amplitude spectrum

if (plotS && any(spectrum))
    % s would now be the power spectral density in dBm
    s = 10*log10(spectrum.*conj(spectrum)*1e3);
    plot(f*1e-9, s, 'color', [78 101 148]/255, 'LineWidth',1.2)
    ylim([mean(s) max(s(100:end))])
    
    xlim([0 Fs/2*1e-9])
    grid on
    ylabel('dBm')
    xlabel('GHz')
    box on
end
end

