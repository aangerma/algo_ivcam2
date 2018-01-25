function [I] = parabFit(corr)
[~,i] = max(corr);
if i == 1
   p = [corr(end),corr(i:i+1)'];
elseif i == numel(corr)
   p = [corr(i-1:i)',corr(1)];
else
   p = corr(i-1:i+1);
end

left_diff = p(1)-p(2);
right_diff = p(3)-p(2);
I = i +  -0.5*(right_diff-left_diff)/(right_diff+left_diff);
end

