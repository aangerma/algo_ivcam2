function [res] = computeError(X, refX)

err = X - refX;

res.mean = mean(abs(err));
res.max = max(abs(err));
res.std = std(abs(err));
res.offset = mean(err);

end

