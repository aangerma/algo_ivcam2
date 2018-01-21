function [out] = distTemporalPairs(ir1, ir2)

[ptsX1, ptsY1] = Validation.findGrid(ir1);
[ptsX2, ptsY2] = Validation.findGrid(ir2);

dist = sqrt((ptsX1-ptsX2).^2 + (ptsY1-ptsY2).^2);
out.distStd = std(dist(:));
out.distMin = min(dist(:));
out.distMax = max(dist(:));

distX = abs(ptsX1-ptsX2);
out.distXStd = std(distX(:));
out.distXMin = min(distX(:));
out.distXMax = max(distX(:));

distY = abs(ptsY1-ptsY2);
out.distYStd = std(distY(:));
out.distYMin = min(distY(:));
out.distYMax = max(distY(:));

end