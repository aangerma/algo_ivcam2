function [K,R,t] = decompose_projmtx(P)

D  = P(:,1:3)*P(:,1:3)';
K  = inv(chol(inv(D)));
t  = K\P(:,4);
R  = K\P(:,1:3);
K  = K/K(end);

%if size(P,1) == 2,
%    K  = [K(1,1) 0 K(1,2); 
%          0      0 K(2,2)];
%    t  = K(:,[1 3])\P(:,4);
%    R  = K\P(:,1:3);
%    R  = R([1 3],:);
%else
%    t  = K\P(:,4);
%    R  = K\P(:,1:3);
%end
