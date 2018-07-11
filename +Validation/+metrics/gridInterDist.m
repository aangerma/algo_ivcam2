function [score, results] = gridInterDist(frames, params)

% params.K - intrinsic matrix

ir = frames(1).i;
z = frames(1).z;

[gridPoints, gridSize] = Validation.aux.findCheckerboard(ir, []);

v = Validation.aux.toVertices(gridPoints, z, params.K);
[e1, e2] = Validation.aux.gridError(v, gridSize, params.squareSize);

score = e1;
results.meanError = e1;
results.rmsError = e2;

end

