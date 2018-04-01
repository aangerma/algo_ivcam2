function z = apply2Dpoli(x,y,ord,coeffs)
assert(length(coeffs)==sum(1:ord+1),'Bad match between the order and the number of coeffs');
polVars = zeros(size(x,1),sum(1:ord+1));
col = 1;
for i = 0:ord
   for n = 0:i
      polVars(:,col) = x.^n.*y.^(i-n);
      col = col + 1;
   end
end

z = polVars*coeffs;
end