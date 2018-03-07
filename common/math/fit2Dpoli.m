function coeffs = fit2Dpoli(x,y,z,ord)

polVars = zeros(size(x,1),sum(1:ord+1));

col = 1;
for i = 0:ord
   for n = 0:i
      polVars(:,col) = x.^n.*y.^(i-n);
%       fprintf('x^%d*y^%d\n',n,i-n);
      col = col + 1;
   end
end



coeffs = pinv(polVars)*z;
% 
% res = polVars*coeffs;
% scatter3(x,y,z)
% hold on 
% scatter3(x,y,res)
end