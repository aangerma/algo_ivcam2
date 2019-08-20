function [pts1,pts2] = createPtsForPtsModel(vertices,pts3d,meanVal,rotmat,shiftVec,checkerSize)
% Get the vertices that are not NaN (not cropped)
notNans = ~isnan(vertices(:,1));
vResult = vertices;
vResult = vResult(notNans,:);
% Perform rotation and scale to the 3D points to get the fitted vertices and normalize to a unit vector
vChecker = pts3d;
vChecker = vChecker(notNans,:);
vFit = (vChecker-meanVal)*rotmat'+shiftVec;

pts1 = [vResult(:,1)./vResult(:,3), vResult(:,2)./vResult(:,3)]';
pts2 = [vFit(:,1)./vFit(:,3), vFit(:,2)./vFit(:,3)]';
end
