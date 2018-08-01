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

v = Validation.aux.pointsToVertices(gridPoints, z, params.camera.K);
[e1, e2] = Validation.aux.gridError(v, gridSize, params.target.squareSize);

results.meanError = e1;
results.rmsError = e2;

results.fidelety = min(1/max(eps, results.meanError), 1000);
score = results.fidelety;
results.score = 'fidelety';
results.units = '1/mm';
results.error = false;

end

