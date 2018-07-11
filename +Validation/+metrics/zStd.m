function [score, results] = zStd(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : struct
%   - roi - regions of interest, percentage [0..1] or [left top width height]

zMaxSubMM = 8;

imgSize = size(frames(1).z);

if ~exist('params','var')
    params = struct;
end

mask = Validation.aux.getRoiMask(imgSize, params);

n = length(frames);

Z = cat(3, frames.z);
noiseStd = nanstd(double(Z)/zMaxSubMM, 0, 3);

%Z = reshape(cat(3, frames.z), imgSize(1)*imgSize(2),[]);
%Z = double(Z(find(mask), :)) / zMaxSubMM;
%noiseStd = nanstd(Z, 0, 2);

results.meanTempNoise = nanmean(noiseStd(mask));
results.maxTempNoise = nanmax(noiseStd(mask));

score = results.meanTempNoise;
results.score = 'meanTempNoise';

end



