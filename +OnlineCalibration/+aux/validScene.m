function [isValidScene] = validScene(frames,params)
isValidScene = false;
if OnlineCalibration.aux.isMovementInImages(frames.yuy2Prev,frames.yuy2,params)
    return;
end
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionDepth;
if ~OnlineCalibration.aux.isEdgeDistributed(frames.weights,frames.sectionMapDepth,params)
    return;
end
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionRgb;
if ~OnlineCalibration.aux.isEdgeDistributed(frames.rgbIDT(:),frames.sectionMapRgb,params)
    return;
end
isValidScene = true;
end

