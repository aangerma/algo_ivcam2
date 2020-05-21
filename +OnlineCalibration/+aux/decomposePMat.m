function [K,R,t] = decomposePMat(P)
firstThreeCols = P(:,1:3);% This is Krgb*R
KSquare = firstThreeCols*firstThreeCols';% This is Krgb*R*R'*Krgb' = Krgb*Krgb'
KSquareInv = inv(KSquare); % Returns a matrix that is equal to: inv(Krgb')*inv(Krgb)
KInv = cholesky3x3(KSquareInv)';% Cholsky decomposition 3 by 3. returns a lower triangular matrix 3x3. Equal to inv(Krgb')
K = inv(KInv);
t = KInv*P(:,4);
R  = KInv*firstThreeCols;
K = K/K(end);
end

function L = cholesky3x3(A)
% https://en.wikipedia.org/wiki/Cholesky_decomposition
L = zeros(3);
for i = 1:3
    for j = 1:i
        if i == j
            L(i,i) = sqrt(A(i,j)-sum(L(i,1:i-1).^2));
        else
            L(i,j) = (A(i,j) - sum(L(i,1:j-1).*L(j,1:j-1)))/L(j,j); 
        end
        
    end
end

end
