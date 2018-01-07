function [out] = distTemporal(ir1, ir2)

[ptsX1, ptsY1] = findGrid(ir1);
[ptsX2, ptsY2] = findGrid(ir2);

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

function [ptsX, ptsY] = findGrid(ir)

ir = double(ir);

ir(sum(ir(:,2:end-1),2)==0,:)=[];

ir_=ir;

ir_(isnan(ir_))=0;
ir_ = histeq(normByMax(ir_));
[pt,bsz]=detectCheckerboardPoints(ir_);

boardSize = bsz - 1;
if(any(boardSize < 2))
    error('Board is not detected');
end

ptsX = reshape(pt(:,1),boardSize);
ptsY = reshape(pt(:,2),boardSize);

end