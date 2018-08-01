function [score, results] = zStd(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : struct
%   - roi - regions of interest, percentage [0..1] or [left top width height]

zMaxSubMM = 8;

imgSize = size(frames(1).z);

if ~exist('params','var')
    params = Validation.aux.defaultMetricsParams();
end

mask = Validation.aux.getRoiMask(imgSize, params);

n = length(frames);

Z = cat(3, frames.z);
noiseStd = nanstd(double(Z)/zMaxSubMM, 0, 3);

results.meanTempNoise = nanmean(noiseStd(mask));
results.maxTempNoise = nanmax(noiseStd(mask));

results.stability = min(1/max(eps, results.meanTempNoise), 1000);
score = results.stability;
results.score = 'stability';
results.units = '1/mm';
results.error = false;

end



