%> @file pconst.m
%> @brief Fast plot constellation of signal
%>
%> Works both with signal_interface and vectors of double.
%> Detect correctly the hold state. (Will disable it at the end).
%>
%> __Example:__
%> @code
%> %s1, s2 can be both signal_interfaces or double vectors
%> pconst(s1, s2); % Plot over previous figure
%> @endcode
%>
%> @author Rasmus Jones
%>
%> @version 1

%>@brief Fast plot real and imaginary part of signal
%>
%> @param varargin Multiple signal_interface or double vectors (don't mix them!)
function pconst( varargin )
c=1;
maxlim=zeros(1,nargin);
for i=1:nargin
    sig = varargin{i};    
    for j=1:sig.N
        subplot(nargin,sig.N,c);
        temp=unique(sig(:,j));
        if( length(temp)<2^11 )            
            plot(real(temp),imag(temp),'d');
        else
            cloudPlot(real(sig(:,j)),imag(sig(:,j)));
        end
%         axis square
        xlabel('I')
        ylabel('Q')
        title(sprintf('%s --- Col. %d', inputname(i), j))        
        c=c+1;
        maxlim(i)=max(abs([xlim ylim maxlim(i)]));
    end    
end
c=1;
for i=1:nargin
    for j=1:sig.N
        subplot(nargin,sig.N,c);
        xlim([-maxlim(i) maxlim(i)])
        ylim([-maxlim(i) maxlim(i)])
        c=c+1;
    end
end
end
