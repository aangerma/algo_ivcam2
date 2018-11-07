function [score, results] = gridInterDist(frames, params)

% params.K - intrinsic matrix

ir = frames(1).i;
z = frames(1).z;

[gridPoints, gridSize] = Validation.aux.findCheckerboard(ir, []);
if (isempty(gridPoints))
    score = nan;
    results.error = true;
    return;
end

v = Validation.aux.pointsToVertices(gridPoints, z, params.camera);
[e1, e2] = Validation.aux.gridError(v, gridSize, params.target.squareSize);

results.meanError = e1;
results.rmsError = e2;

score = results.meanError;
results.score = 'meanError';
results.units = 'mm';
results.error = false;

end

