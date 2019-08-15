function [targetOffset] = detectMarkersAndFindOffset(calibParams,IRimage,zImage,detectedGridPointsV,CamParam)
%% find circels 
markerCenter=[115,191]; 
markerCenterV=Validation.aux.pointsToVertices(markerCenter-1,zImage,CamParam);

%% 
gridOrigin=detectedGridPointsV(1,:);
% dy = horizontal offset due to rot90
dy=(gridOrigin(1)-markerCenterV(1))/calibParams.target.cbSquareSz; dy=-sign(dy)*ceil(abs(dy)); 
dx=(gridOrigin(2)-markerCenterV(2))/calibParams.target.cbSquareSz; dx=sign(dx)*floor(abs(dx)); 

targetOffset.offX=calibParams.target.whiteMarkers.horizontalCBoffset+dx;
targetOffset.offY=calibParams.target.whiteMarkers.verticalCBoffset+dy;


end

