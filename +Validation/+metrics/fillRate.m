function [score, results] = fillRate(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : struct
%   - roi - regions of interest
%   - K - intrinsic matrix

sz = size(frames(1).z);

if (~exist('params','var') || ~isfield(params, 'roi'))
    % 80 percent
    roi = [sz(2)*0.1+1 sz(1)*0.1+1 sz(2)*0.8 sz(1)*0.8];
else
    roi = params.roi;
end

sz = size(frames(1).z);

roiV = round(roi(2)):round(roi(2)+roi(4)-1);
roiH = round(roi(1)):round(roi(1)+roi(3)-1);

img = frames(1).z(roiV, roiH);

score = sum(img(:)~=0) / numel(img);

results.fillRate = score;

end

