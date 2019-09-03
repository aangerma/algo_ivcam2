function [pts1,pts2] = createPtsForPtsModel(vertices,pts3d,meanVal,rotmat,shiftVec,checkerSize)
% Get the vertices that are not NaN (not cropped)
notNans = ~isnan(vertices(:,1));
verticesNoNans = vertices(notNans,:);
pts3d = pts3d(notNans,:);
% Perform rotation and scale to the 3D points to get the fitted vertices and normalize to a unit vector
vFit = (pts3d-meanVal)*rotmat'+shiftVec;

pts1 = [verticesNoNans(:,1)./verticesNoNans(:,3), verticesNoNans(:,2)./verticesNoNans(:,3)]';
pts2 = [vFit(:,1)./vFit(:,3), vFit(:,2)./vFit(:,3)]';
end
