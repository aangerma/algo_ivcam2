function [validInputs,directionData,dbg] = inputValidityChecks(frame,params)
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
% one in which we converged


% 1. Enough Edges in RGB image (Lights off bug fix)
[dbg.rgbEdgesSpread,dbg.rgbEdgesSpreadDbg] = OnlineCalibration.aux.checkEnoughRgbEdges(frame.rgbEdge,frame.sectionMapRgb,params);

% 2. Enough Edges in enough locations (3/4 quarters)
[dbg.depthEdgesSpread,dbg.depthEdgesSpreadDbg] = OnlineCalibration.aux.checkEdgesSpatialSpread(frame.sectionMapDepth,params.depthRes,params.pixPerSectionDepthTh,params.minSectionWithEnoughEdges,params.numSections);

% 3+4. Enough Edges in enough directions (2/4 directions) and Std Per Dir (weights will be
% normalized by direction,Normalize by weights is done in a seperate
% function)
[dbg.depthEdgesDirSpread,directionData,dbg.depthEdgesDirSpreadDbg] = OnlineCalibration.aux.checkEdgesDirSpread(frame.dirPerPixel,frame.xim,frame.yim,params.depthRes,params);

% 5. Check movement between this scene and the previous good one
[dbg.isMovementFromLastSuccess,dbg.movingPixelsFromLastSuccess] = OnlineCalibration.aux.isMovementInImages(frame.lastValidYuy2,frame.yuy2,params);

validInputs = dbg.rgbEdgesSpread & dbg.depthEdgesSpread & dbg.depthEdgesDirSpread & dbg.isMovementFromLastSuccess;
dbg.validInputs = validInputs;
end

