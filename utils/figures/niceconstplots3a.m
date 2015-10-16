% Robert Borkowski, rbor@fotonik.dtu.dk
% Technical University of Denmark
% v1.3a 29.11.2012
close all
cplx2mat = @(z)[real(z(:)) imag(z(:))];
xmodnorm = @(varargin)varargin{1}*modnorm(varargin{:});

M = 16;
h = modem.qammod('M',M);
M = length(h.Constellation);
signal = h.modulate(randi([0 M-1],4e4,1));
signal = xmodnorm(signal,'avpow',1);
signal = awgn(signal,20,'measured');
figure,plot(signal,'.');

x = cplx2mat(signal);

neigh = zeros(size(x,1),1);
r = 0.1;
% xy = [r r];
for xi=1:size(x,1)
    neigh(xi) = nnz(sum(bsxfun(@minus,x(xi,:),x).^2,2)<=r^2);
% neigh(xi) = nnz(all(bsxfun(@lt,abs(bsxfun(@minus,x(xi,:),x)),xy),2));
end

figure
C = 64; % number of colors
% cmap = colormap(jet(C));
% cmap = colormap([linspace(0,0.85,C)' zeros(C,2)]);
% cmap = colormap(hot(C));
cmap = colormap(constcmap(C,[1 2])); %[1 2] red, [3 2] blue
cols = round(scaledata(neigh,1,size(cmap,1)));
for c=1:size(cmap,1)
    points = x(cols==c,:);
    plot(points(:,1),points(:,2),'Marker','.','LineStyle','none','Color',cmap(c,:));
    hold on
end
axis square
caxis(lims(neigh));
colorbar