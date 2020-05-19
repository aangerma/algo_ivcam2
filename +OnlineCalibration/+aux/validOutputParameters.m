function [clippedParams,dbg,validOutputStruct] = validOutputParameters(frame,params,newParamsP,newParamsK2DSM,originalParams,iterationFromStart)
dbg = struct;

% Clip current movement by pixels
% It makes sense that the first fix will be large, but we expect it to
% converge durring stream
% In the case we have a large fix, we clip it so the new params will move
% the uv mapping less
[~,clippedParams,validOutputStruct.xyMovement] = OnlineCalibration.aux.clipMovement(frame,params,newParamsK2DSM,iterationFromStart);

% Invalidate movement which is far away from origin
% In case we moved very far from the original location, we ignore the fix
% we just calculated and take the parameters form the start of the
% iterations
[uvMapOrig,~,~] = OnlineCalibration.aux.projectVToRGB(frame.originalVertices,originalParams.rgbPmat,originalParams.Krgb,originalParams.rgbDistort,originalParams);
[uvMapNew,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newParamsK2DSM.rgbPmat,newParamsK2DSM.Krgb,newParamsK2DSM.rgbDistort,newParamsK2DSM);
validUvs = OnlineCalibration.aux.isInsideImage(uvMapOrig,flip(params.rgbRes)) &  OnlineCalibration.aux.isInsideImage(uvMapNew,flip(params.rgbRes));
validOutputStruct.xyMovementFromOrigin = mean(sqrt(sum((uvMapOrig(validUvs,:)-uvMapNew(validUvs,:)).^2,2)));
if validOutputStruct.xyMovementFromOrigin > params.maxXYMovementFromOrigin
    clippedParams = params;
end



% Check and see that the score didn't increased by a lot in one image
% section and decreased in the others
[c1,costVecOld] = OnlineCalibration.aux.calculateCost(frame.originalVertices,frame.weights,frame.rgbIDT,params);
[c2,costVecNew] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,newParamsP);

scoreDiffPerVertex = costVecNew-costVecOld;
for i = 0:(params.numSectionsH*params.numSectionsV)-1
    scoreDiffPersection(i+1) = nanmean(scoreDiffPerVertex(frame.sectionMapDepth == i));
end
dbg.scoreDiffPerVertex = scoreDiffPerVertex;
dbg.scoreDiffPersection = scoreDiffPersection;
validOutputStruct.improvementPerSection = scoreDiffPersection;
validOutputStruct.minImprovementPerSection = min(scoreDiffPersection);
validOutputStruct.maxImprovementPerSection = max(scoreDiffPersection);


end
