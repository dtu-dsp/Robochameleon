%> @file pabsh.m
%> @brief Fast plot pulse power envelope
%>
%> If input is a signal interface, plot the correct time axis generated from Rs, Fs.
%>
%> __Example:__
%> @code
%> %s1, s2, s3 can be both signal_interfaces or double vectors
%> pabs(s1);
%> pabsh(s2, s3); % Plot over previous figure
%> @endcode
%>
%> @author Simone Gaiarin
%>
%> @version 1

%> @brief Fast plot pulse power envelope
%>
%> @param varargin Multiple signal_interface or double vectors (don't mix them!)
function pabsh( varargin )
hold on;
for i=1:nargin
    sig = varargin{i};
    try
        % Try to generate a time axis if signal_interface
        t = genTimeAxisSig(varargin{i});
        plot(t, abs(sig(:,:)).^2);
        xlabel('Time [s]');
    catch e
        % Otherwise just plot, both signal_interface or vector
        plot(abs(sig(:,:)).^2);
        xlabel('Time [samples]');
    end
    
end
hold off;
ylabel('Power [W]');
title('Power envelope');
end
