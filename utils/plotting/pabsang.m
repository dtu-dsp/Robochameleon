%> @file pabsang.m
%> @brief Fast plot power envelope and phase of signal
%>
%> Works both with signal_interface and vectors of double.
%> Detect correctly the hold state. (Will disable it at the end).
%>
%> __Example:__
%> @code
%> %s1, s2, s3 can be both signal_interfaces or double vectors
%> pabsang(s1);
%> hold on;
%> pabsang(s2, s3); % Plot over previous figure
%> @endcode
%>
%> @author Simone Gaiarin
%>
%> @version 1

%>@brief Fast plot power envelope and phase of signal
%>
%> @param varargin Multiple signal_interface or double vectors (don't mix them!)
function pabsang( varargin )
if ~ishold
    figure;
end
for i=1:nargin
    sig = varargin{i};
    try
        % Try to generate a time axis if signal_interface
        t = genTimeAxisSig(sig);
        labelx = 'Time [s]';
    catch e
        % Otherwise just plot, both signal_interface or vector
        t = 1:length(sig(:,:));
        labelx = 'Time [samples]';
    end
    hold on;
    subplot(1,2,1);
    plot(t, abs(sig(:,:)));
    title('Power envelope [W]');
    xlabel(labelx);
    hold on;
    subplot(1,2,2);
    plot(t, angle(sig(:,:))/pi);
    title('Phase [Normalized over pi]');
    ylim([-1.1 1.1]);
    xlabel(labelx);
    hold off;
end
end
