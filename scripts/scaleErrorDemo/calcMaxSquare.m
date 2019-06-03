function [maxSquareL,maxSquareA,ed,edgeErrs] = calcMaxSquare(px,py,pz)
    pts = cat(3,px,py,pz);
    ed(1) = sqrt(sum(squeeze(pts(1,end,:) - pts(1,1,:)).^2));
    ed(2) = sqrt(sum(squeeze(pts(end,end,:) - pts(1,end,:)).^2));
    ed(3) = sqrt(sum(squeeze(pts(end,1,:) - pts(end,end,:)).^2));
    ed(4) = sqrt(sum(squeeze(pts(1,1,:) - pts(end,1,:)).^2));
    maxSquareL = sum(ed);
    maxSquareA = mean(ed([1 3])).*mean(ed([2 4]));
    edgeErrs = abs([diff(ed([1 3])) diff(ed([2 4]))])./2;
end
