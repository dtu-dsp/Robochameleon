function sigout=addskew(sigin,skew,Fs)

sigin=sigin(:)';
Npoints=length(sigin);
freqGrid=[0:(Npoints/2) (-Npoints/2+1):1:-1]/Npoints;

SkewPhase=exp(1i*2*pi*skew*Fs*freqGrid);
SIGIN=fft(sigin);
SIGOUT=SIGIN.*SkewPhase;
sigout=real(ifft(SIGOUT));
sigout=sigout(:);
end