function [isValidScene,validSceneStruct] = validScene(frames,params)
validSceneStruct = struct;
validSceneStruct.invalidReason = '';
isValidScene = true;

[isMovement,validSceneStruct.movingPixels] = OnlineCalibration.aux.isMovementInImages(frames.yuy2Prev,frames.yuy2,params);
if isMovement
    if ~isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'Movement'];
    
    validSceneStruct.isValid = false;
    isValidScene = false;
end
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionDepth;
[goodEdgeDistribution,validSceneStruct.edgeDistributionMinMaxRatioDepth,validSceneStruct.edgeDistributionMinWeightPerSectionDepth] = OnlineCalibration.aux.isEdgeDistributed(frames.weights,frames.sectionMapDepth,params);
if ~goodEdgeDistribution
    if isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'EdgeDistributionDepth'];
        
    validSceneStruct.isValid = false;
    isValidScene = false;
end
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionRgb;
[goodEdgeDistributionRgb,validSceneStruct.edgeDistributionMinMaxRatioRgb,validSceneStruct.edgeDistributionMinWeightPerSectionRgb] = OnlineCalibration.aux.isEdgeDistributed(frames.rgbIDT(:),frames.sectionMapRgb,params);
if ~goodEdgeDistributionRgb
    if isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'EdgeDistributionRgb'];
    validSceneStruct.isValid = false;
    isValidScene = false;
end

[goodEdgeDirDistribution,validSceneStruct.dirRatio1,validSceneStruct.perpRatio,validSceneStruct.dirRatio2,validSceneStruct.weightsPerDir] = OnlineCalibration.aux.isGradDirBalanced(frames,params);
if ~goodEdgeDirDistribution
    if isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end 
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'EdgeDirDistribution'];
    validSceneStruct.isValid = false;
    isValidScene = false;
end


global sceneResults;
if isstruct(sceneResults)
    sceneResults.validScene = validSceneStruct;
end
end

