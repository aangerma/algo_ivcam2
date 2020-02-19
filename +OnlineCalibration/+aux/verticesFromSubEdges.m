function [vertices,W,edgePts] = verticesFromSubEdges(frame, params, options)
% For each pixel we need:
% 1. Determine if its an edge pixel
% 2. Find the subpixel location of the edge
% 3. Turn it into a vertex
% 4. Determine the weight of the vertex

% Find edges in IR image
Ei = OnlineCalibration.aux.calcEImage(frame.i,options);
IREdgeMask = Ei>options.gradITh;
% Find sub edges
[subEdgeIm,suppresedE,closeEdgeZVal] = OnlineCalibration.aux.subpixelEdges(frame.z,options.gradZTh,IREdgeMask);

% Invalidate by IR and set the weights of the edges
wIm = suppresedE;
validMask = wIm>0;
W = wIm(validMask);

% calculate the vertices of the chosen pixels
subX = subEdgeIm(:,:,1)-1;
subY = subEdgeIm(:,:,2)-1;

subPoints = [subX(validMask),subY(validMask),ones(size(subY(validMask)))];

vertices = subPoints*(pinv(params.Kdepth)').*closeEdgeZVal(validMask)/single(params.zMaxSubMM);
edgePts = subPoints(:,1:2)+1;




end