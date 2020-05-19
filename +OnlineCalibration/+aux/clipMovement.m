function [requiredClipping,clippedParams,xyMovement] = clipMovement(frame,params,newParams,iterationFromStart)
%CLIPMOVEMENT checks if the movement was too large in this iteration and
%clips the changes in the extrinsics and RGB intrinsics accordingly
clippedParams = newParams;
% Location at the beginning of the current AC iteration
[uvMapPrev,~,~] = OnlineCalibration.aux.projectVToRGB(frame.originalVertices,params.rgbPmat,params.Krgb,params.rgbDistort,params);
[uvMapNew,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newParams.rgbPmat,newParams.Krgb,newParams.rgbDistort,newParams);
validUvs = OnlineCalibration.aux.isInsideImage(uvMapPrev,flip(params.rgbRes)) &  OnlineCalibration.aux.isInsideImage(uvMapNew,flip(params.rgbRes));
uvMapPrev = uvMapPrev(validUvs,:);
uvMapNew = uvMapNew(validUvs,:);
xyMovement = mean(sqrt(sum((uvMapPrev-uvMapNew).^2,2)));

maxMovementInThisIteration = params.maxXYMovementPerIteration(min(length(params.maxXYMovementPerIteration),iterationFromStart));
requiredClipping = xyMovement > maxMovementInThisIteration;
if requiredClipping
    mulFactor = maxMovementInThisIteration/xyMovement;
   
    diff = newParams.rgbPmat - params.rgbPmat;
    clippedParams.rgbPmat = params.rgbPmat + diff*mulFactor;
    [clippedParams.Krgb,clippedParams.Rrgb,clippedParams.Trgb] = OnlineCalibration.aux.decomposePMat(clippedParams.rgbPmat);
    clippedParams.Krgb(1,2) = 0;
    [clippedParams.xAlpha,clippedParams.yBeta,clippedParams.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(clippedParams.Rrgb);
end


end

