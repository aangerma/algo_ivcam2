function [isOutputValid,newParams,dbg] = validOutputParameters(frame,params,newParams,originalParams,iterationFromStart)
isOutputValid = 1;

% Clip current movement by pixels
[uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
[uvMapNew,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newParams.rgbPmat,newParams.Krgb,newParams.rgbDistort);

xyMovement = mean(sqrt(sum((uvMap-uvMapNew).^2,2)));
maxMovementInThisIteration = params.maxXYMovementPerIteration(min(length(params.maxXYMovementPerIteration),iterationFromStart));
if xyMovement > maxMovementInThisIteration
    pMatDiff = newParams.rgbPmat - params.rgbPmat;
    newParams.rgbPmat = params.rgbPmat + pMatDiff*maxMovementInThisIteration/xyMovement;
    fprintf('Movement too large, clipped movement from %f to %f pixels.\n',xyMovement,maxMovementInThisIteration);
end

% Invalidate movement which is far away from origin
[uvMapOrig,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,originalParams.rgbPmat,originalParams.Krgb,originalParams.rgbDistort);
[uvMapNew,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newParams.rgbPmat,newParams.Krgb,newParams.rgbDistort);
xyMovementFromOrigin = mean(sqrt(sum((uvMapOrig-uvMapNew).^2,2)));
if xyMovementFromOrigin > params.maxXYMovementFromOrigin
    fprintf('Drifted more than %f pixels from original state. Invalid fix.\n',params.maxXYMovementFromOrigin); 
    isOutputValid = 0;
    newParams = params;
end


% Check and see that the score didn't increased by a lot in one image
% section and decreased in the others
[c1,costVecOld] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
[c2,costVecNew] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,newParams);
scoreDiffPerVertex = costVecNew-costVecOld;
for i = 0:(params.numSectionsH*params.numSectionsV)-1
    scoreDiffPersection(i+1) = nanmean(scoreDiffPerVertex(frame.sectionMapDepth == i));
end
if any(scoreDiffPersection<0)
    fprintf('Some image sections were hurt in the optimization. Invalidating fix.\n'); 
    isOutputValid = 0;
    newParams = params;
end
dbg.scoreDiffPerVertex = scoreDiffPerVertex;
dbg.scoreDiffPersection = scoreDiffPersection;

end

