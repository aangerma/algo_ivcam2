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

% Step 5 - convert back to pixels

% Step 6 - resample image
%Use methodology from du.math.imageWarp