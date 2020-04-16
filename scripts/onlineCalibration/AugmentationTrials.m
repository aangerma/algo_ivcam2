% Step 1 - get ACC data
accPath = 'W:\BIG PBS\HENG-3317\F9340558\ACC1';
data = Calibration.tables.getCalibDataFromCalPath([], accPath);

% Step 2 - convert image to vertices
frameSize = [768,1024];
Kworld = Pipe.calcIntrinsicMat(data.regs, frameSize);
[y, x] = ndgrid(1:frameSize(1), 1:frameSize(2));
vertices = [x(:), y(:), ones(prod(frameSize),1)] * (inv(Kworld))';

% Step 3 - convert vertices to DSM
rpt = Utils.convert.RptToVertices(vertices, regs, data.tpsUndistModel, 'inverse');

% Step 4 - apply DSM manipulation
rptDist = [rpt(:,1), ax*rpt(:,2)+bx, ay*rpt(:,3)+by];

% Step 5 - convert back to pixels
verticesDist = Utils.convert.RptToVertices(rptDist, regs, data.tpsUndistModel, 'direct');
pixelsDist = (verticesDist./verticesDist(:,3)) * Kworld';
xDist = reshape(pixelsDist(:,1), size(x));
yDist = reshape(pixelsDist(:,1), size(y));

% Step 6 - resample image
warpedFrame.i = du.math.imageWarp(frame.i, yDist(:), xDist(:));
warpedFrame.z = du.math.imageWarp(frame.z, yDist(:), xDist(:));

