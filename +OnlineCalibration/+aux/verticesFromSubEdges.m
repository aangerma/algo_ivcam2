function [vertices,W,edgePts] = verticesFromSubEdges(frame, params, options)

% Find sub edges

[subEdgeIm,suppresedE,closeEdgeVal] = OnlineCalibration.aux.subpixelEdges(frame.z,options.gradZTh);

% Invalidate by IR and set the weights of the edges
Ei = OnlineCalibration.aux.calcEImage(frame.i,options);
wIm = (Ei>options.gradITh ).*suppresedE;
wIm(wIm<options.gradZTh) = 0;
validMask = wIm>0;
W = wIm(validMask);

% calculate the vertices of the chosen pixels
subX = subEdgeIm(:,:,1)-1;
subY = subEdgeIm(:,:,2)-1;

subPoints = [subX(validMask),subY(validMask),ones(size(subY(validMask)))];

vertices = subPoints*(pinv(params.Kdepth)').*closeEdgeVal(validMask)/single(params.zMaxSubMM);
edgePts = subPoints(:,1:2)+1;




end