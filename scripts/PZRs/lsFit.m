function [c, errMean, errMax, errRMS, err] = lsFit(x1, x2, y)
n = length(x1);

X1 = reshape(x1, [n 1]);
X2 = reshape(x2, [n 1]);
Y = reshape(y, [n 1]);

A = [X1 X2 ones(n,1)];
c = (A'*A)\(A'*Y);
err = abs(A*c-Y);
errMean = mean(err);
errMax = max(err);
errRMS = rms(err);
end

