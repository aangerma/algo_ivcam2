function [isOutputValid,newParams,dbg,validOutputStruct] = validOutputParameters(frame,params,newParams,originalParams,iterationFromStart)
dbg = struct;
isOutputValid = 1;
validOutputStruct.isValid = 1;

%% Clip current movement by pixels
   [uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
[uvMapNew,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newParams.rgbPmat,newParams.Krgb,newParams.rgbDistort);
dbg.uvMap = uvMap;
dbg.uvMapNew = uvMapNew;

xyMovement = mean(sqrt(sum((uvMap-uvMapNew).^2,2)));
dbg.xyMovement = xyMovement;
validOutputStruct.xyMovement = xyMovement;
maxMovementInThisIteration = params.maxXYMovementPerIteration(min(length(params.maxXYMovementPerIteration),iterationFromStart));
if xyMovement > maxMovementInThisIteration
    mulFactor = maxMovementInThisIteration/xyMovement;
    if ~strcmp(params.derivVar,'P')
        optParams = {'xAlpha';'yBeta';'zGamma';'Trgb';'Kdepth';'Krgb'};
        for fn = 1:numel(optParams)
            diff = newParams.(optParams{fn}) - params.(optParams{fn});
            newParams.(optParams{fn}) = params.(optParams{fn}) + diff*mulFactor;
        end
        newParams.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(newParams.xAlpha,newParams.yBeta,newParams.zGamma);
        newParams.rgbPmat = newParams.Krgb*[newParams.Rrgb,newParams.Trgb];
    else
        diff = newParams.rgbPmat - params.rgbPmat;
        newParams.rgbPmat = params.rgbPmat + diff*mulFactor;

    end
    fprintf('Movement too large, clipped movement from %f to %f pixels.\n',xyMovement,maxMovementInThisIteration);
end

%% Invalidate movement which is far away from origin
[uvMapOrig,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,originalParams.rgbPmat,originalParams.Krgb,originalParams.rgbDistort);
[uvMapNew,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newParams.rgbPmat,newParams.Krgb,newParams.rgbDistort);
xyMovementFromOrigin = mean(sqrt(sum((uvMapOrig-uvMapNew).^2,2)));
validOutputStruct.xyMovementFromOrigin = xyMovementFromOrigin;
if xyMovementFromOrigin > params.maxXYMovementFromOrigin
    fprintf('Drifted more than %f pixels from original state. Invalid fix.\n',params.maxXYMovementFromOrigin); 
    isOutputValid = 0;
    validOutputStruct.isValid = 0;
    newParams = params;
end


%% Check and see that the score didn't increased by a lot in one image
% section and decreased in the others
[c1,costVecOld] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
[c2,costVecNew] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,newParams);
scoreDiffPerVertex = costVecNew-costVecOld;
for i = 0:(params.numSectionsH*params.numSectionsV)-1
    scoreDiffPersection(i+1) = nanmean(scoreDiffPerVertex(frame.sectionMapDepth == i));
end
dbg.scoreDiffPerVertex = scoreDiffPerVertex;
dbg.scoreDiffPersection = scoreDiffPersection;
validOutputStruct.improvementPerSection = scoreDiffPersection;
validOutputStruct.minImprovementPerSection = min(scoreDiffPersection);
validOutputStruct.maxImprovementPerSection = max(scoreDiffPersection);
if any(scoreDiffPersection<0)
    fprintf('Some image sections were hurt in the optimization. Invalidating fix.\n'); 
    isOutputValid = 0;
    validOutputStruct.isValid = 0;
    newParams = params;
end
validOutputStruct.newParams = newParams;

global sceneResults;
if isstruct(sceneResults)
    sceneResults.validOutput = validOutputStruct;
end

end

