function J = constcmap(m,t)

J = zeros(m,3);

J(:,t(1)) = [linspace(0,1,ceil(m/2))'; ones(floor(m/2),1)];
J(ceil(m/2):end,t(2)) = linspace(0,1,floor(m/2)+1)';