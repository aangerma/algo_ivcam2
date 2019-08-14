function [pts1,pts2] = createPtsForPtsModel(vertices,pts3d,meanVal,rotmat,shiftVec,checkerSize)
% Get the vertices that are not NaN (not cropped)
vertices = reshape(vertices,[checkerSize,3]);
[vResult,rows,cols] = Calibration.aux.CBTools.slimNans(vertices);
vResult = reshape(vResult,[],3);
% Perform rotation and scale to the 3D points to get the fitted vertices and normalize to a unit vector
vChecker = reshape(pts3d,checkerSize(1),checkerSize(2),3);
vChecker = vChecker(rows,cols,:);
vChecker = reshape(vChecker,[],3);
vFit = (vChecker-meanVal)*rotmat'+shiftVec;

pts1 = [vResult(:,1)./vResult(:,3), vResult(:,2)./vResult(:,3)]';
pts2 = [vFit(:,1)./vFit(:,3), vFit(:,2)./vFit(:,3)]';
end
