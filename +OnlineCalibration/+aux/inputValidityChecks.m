function [validInputs,directionData,dbg] = inputValidityChecks(frame,params,outputBinFilesPath)
% This function checks for specific cases in which we expect poor
% performance of the AC2 algorithm.
% Covered Cases (By priority):
% 1. Enough Edges in RGB image (Lights off bug fix)
% 2. Enough Edges in enough locations (3/4 quarters)
% 3. Enough Edges in enough directions (2/4 directions)
% 4. Large enough STD of edges in the cosen direction (weights will be
% normalized by direction)  (Normalize by weights is done in a seperate
% function)
% 5. Verify there is movement in RGB between this scene and the previous
% 6. Check for saturation in the depth
% one in which we converged
if ~exist('outputBinFilesPath','var')
    outputBinFilesPath = [];
end

% 1. Enough Edges in RGB image (Lights off bug fix)
[dbg.rgbEdgesSpread,dbg.rgbEdgesSpreadDbg] = OnlineCalibration.aux.checkEdgesSpatialSpread(frame.sectionMapRgbEdges,params.rgbRes,params.pixPerSectionRgbTh,params.minSectionWithEnoughEdges,params.numSections);


% 2. Enough Edges in enough locations (3/4 quarters)
[dbg.depthEdgesSpread,dbg.depthEdgesSpreadDbg] = OnlineCalibration.aux.checkEdgesSpatialSpread(frame.sectionMapDepth,params.depthRes,params.pixPerSectionDepthTh,params.minSectionWithEnoughEdges,params.numSections);

% 3+4. Enough Edges in enough directions (2/4 directions) and Std Per Dir (weights will be
% normalized by direction,Normalize by weights is done in a seperate
% function)
[dbg.depthEdgesDirSpread,directionData,dbg.depthEdgesDirSpreadDbg] = OnlineCalibration.aux.checkEdgesDirSpread(frame.dirPerPixel,frame.xim,frame.yim,params.depthRes,params,outputBinFilesPath);

% 5. Check movement between this scene and the previous good one
if ~params.manualTrigger
    [dbg.isMovementFromLastSuccess,dbg.movingPixelsFromLastSuccess] = OnlineCalibration.aux.isMovementInImages(frame.lastValidYuy2,frame.yuy2,params);
else
    dbg.isMovementFromLastSuccess = 1;
    dbg.movingPixelsFromLastSuccess = 0;
end
% 6. Check for saturation in the IR image
[dbg.depthIsntSaturated,dbg.depthSaturationDbg] = OnlineCalibration.aux.checkForSaturation(frame.i,params.irSaturationValue,params.irSaturationRatioTh,outputBinFilesPath);

validInputs = dbg.rgbEdgesSpread && dbg.depthEdgesSpread && dbg.depthEdgesDirSpread && dbg.isMovementFromLastSuccess && dbg.depthIsntSaturated;
dbg.validInputs = validInputs;
end

