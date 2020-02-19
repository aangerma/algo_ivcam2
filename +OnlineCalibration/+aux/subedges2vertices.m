function [vertices] = subedges2vertices(frame,params)
validPixels = frame.zEdgeSubPixel(:,:,1) > 0;
subX = frame.zEdgeSubPixel(:,:,2)-1;
subY = frame.zEdgeSubPixel(:,:,1)-1;
subPoints = [subX(validPixels),subY(validPixels),ones(size(subY(validPixels)))];
zValues = frame.zValuesForSubEdges(validPixels);
vertices = subPoints*(pinv(params.Kdepth)').*zValues/single(params.zMaxSubMM);
end

