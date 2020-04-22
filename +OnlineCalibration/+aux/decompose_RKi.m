function [R,Kinv] = decompose_RKi(RKi)
%DECOMPOSE_RKI Decompose R*Kinv to its components

Kinv = chol(RKi'*RKi);
R = RKi\Kinv;


% D  = P(:,1:3)*P(:,1:3)';
% K  = inv(chol(inv(D)));
% t  = K\P(:,4);
% R  = K\P(:,1:3);
% K  = K/K(end);

end

