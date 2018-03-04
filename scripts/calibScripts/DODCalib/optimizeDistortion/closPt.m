function [rowI] = closPt(points,ref)
diff = sum((points-ref).^2,2);
[~,rowI] = min(diff);
end

