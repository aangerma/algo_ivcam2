function [corners3d, cornersIndx] = create3DCorners(targetInfo)
    [x, y] = ndgrid(1:targetInfo.cornersX,1:targetInfo.cornersY);
    cornersIndx = [x(:) y(:)]';
    corners3d = bsxfun(@times,cornersIndx-1,[targetInfo.mmPerUnitX;targetInfo.mmPerUnitY]);
    corners3d = [corners3d;zeros(1,size(corners3d,2))];
end