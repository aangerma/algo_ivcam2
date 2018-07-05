function [score] = fillRate(frames, params)

% frames 1×n struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : struct
%   - roi - regions of interest
%   - K - intrinsic matrix

sz = size(frames(1).z);

roiV = 1:sz(1);
roiH = 1:sz(2);

img = frames(1).z(roiV, roiH);

score = sum(img(:)~=0) / numel(img);

end

