function [isValidScene] = validScene(frames,params)
isValidScene = ~OnlineCalibration.aux.isMovementInImages(frames.yuy2Prev,frames.yuy2,params);
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionDepth;
isValidScene = isValidScene & OnlineCalibration.aux.isEdgeDistributed(frames.weights,frames.sectionMapDepth,params);
params.minWeightedEdgePerSection = params.minWeightedEdgePerSectionRgb;
isValidScene = isValidScene & OnlineCalibration.aux.isEdgeDistributed(frames.rgbIDT(:),frames.sectionMapRgb,params);

end

