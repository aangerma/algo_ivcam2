function [score, results] = gridEdgeSharp(frames, params)

% params.K - intrinsic matrix

ir = frames(1).i;
z = frames(1).z;

results = Validation.aux.edgeTrans(ir);

if (isempty(results.gridSize))
    score = nan;
    results.error = true;
    return;
end

irs = cat(3, frames.i);
irMean = mean(irs, 3);
results.meanFrame = Validation.aux.edgeTrans(irMean);
results.sharpness = results.horizMean;


score = results.sharpness;
results.score = 'sharpness';
results.units = 'pixels';
results.error = false;

end

