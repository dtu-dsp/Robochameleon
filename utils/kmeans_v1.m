% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% K-MEANS algorithm - Copyrigths Edson Porto da Silva, DTU - Fotonik
% 
% Inputs: 
%           - Init_posMatrix: initial particles positions;
%           - Symb_Vector: received constellation (symbols + noise, rotation, etc);
%           - Iterations: number of k-means interations;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function centers = kmeans_v1(Init_posMatrix, Symb_Vector, Iterations)

c = [real(Init_posMatrix); imag(Init_posMatrix)];
x = [real(Symb_Vector); imag(Symb_Vector)];
dimensao = 2;
gama = 0.02;
Nrbf = length(c(1,:));
l = zeros(1,Nrbf); 
ca = zeros(dimensao,Nrbf);

%% k-means

for k = 1:Iterations
    for j = 1:Nrbf
        l(j) = abs((x(:,k)-c(:,j))'*(x(:,k)-c(:,j)));
    end
    [dist, i] = min(l);
    
    c(:,i) = c(:,i) + gama*(x(:,k)-c(:,i)); % Winner adaptation
    %     figure(2),plot(c(1,:),c(2,:),'*')
    %     grid on;
    %     xlim([-2 2]);
    %     ylim([-2 2]);
    %     if mod(k,100) == 0
    %     gama = gama-k/100000;
    %     end
    
end
centers = c;
end


