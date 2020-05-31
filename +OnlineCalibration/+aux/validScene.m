function [isValidScene,validSceneStruct,isMovement] = validScene(frames,params,outputBinFilesPath)
validSceneStruct = struct;
validSceneStruct.invalidReason = '';
isValidScene = true;
validSceneStruct.isValid = 1;

[isMovement,validSceneStruct.movingPixels] = OnlineCalibration.aux.isMovementInImages(frames.yuy2Prev,frames.yuy2,params,outputBinFilesPath);
if isMovement
    if ~isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'Movement'];
    
    validSceneStruct.isValid = false;
    isValidScene = false;
end
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionDepth;
[goodEdgeDistribution,validSceneStruct.edgeDistributionMinMaxRatioDepth,validSceneStruct.edgeWeightDistributionPerSectionDepth] = OnlineCalibration.aux.isEdgeDistributed(frames.weights,frames.sectionMapDepth,params);
if ~goodEdgeDistribution
    if ~isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'EdgeDistributionDepth'];
        
    validSceneStruct.isValid = false;
    isValidScene = false;
end
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'depthEdgeWeightDistributionPerSectionDepth',validSceneStruct.edgeWeightDistributionPerSectionDepth,'double');

params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionRgb;
[goodEdgeDistributionRgb,validSceneStruct.edgeDistributionMinMaxRatioRgb,validSceneStruct.edgeWeightDistributionPerSectionRgb] = OnlineCalibration.aux.isEdgeDistributed(frames.rgbIDT(:),frames.sectionMapRgb,params);
if ~goodEdgeDistributionRgb
    if ~isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'EdgeDistributionRgb'];
    validSceneStruct.isValid = false;
    isValidScene = false;
end

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightDistributionPerSectionRgb',validSceneStruct.edgeWeightDistributionPerSectionRgb,'double');

[goodEdgeDirDistribution,validSceneStruct.dirRatio1,validSceneStruct.perpRatio,validSceneStruct.dirRatio2,validSceneStruct.edgeWeightsPerDir] = OnlineCalibration.aux.isGradDirBalanced(frames,params);
if ~goodEdgeDirDistribution
    if ~isempty(validSceneStruct.invalidReason)
        validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'&'];
    end 
    validSceneStruct.invalidReason = [validSceneStruct.invalidReason,'EdgeDirDistribution'];
    validSceneStruct.isValid = false;
    isValidScene = false;
end

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightsPerDir',validSceneStruct.edgeWeightsPerDir,'double');

global sceneResults;
if isstruct(sceneResults)
    sceneResults.validScene = validSceneStruct;
end
end

