function [I] = parabFit(corr)
[~,i] = max(corr);
p = corr(i-1:i+1);
left_diff = p(1)-p(2);
right_diff = p(3)-p(2);
I = i +  -0.5*(right_diff-left_diff)/(right_diff+left_diff);
end

