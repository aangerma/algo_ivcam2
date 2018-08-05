function [score, results] = fillRate(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : struct
%   - roi - regions of interest, percentage [0..1] or [left top width height]


imgSize = size(frames(1).z);

if ~exist('params','var')
    params = struct;
end

mask = Validation.aux.getRoiMask(imgSize, params);

n = length(frames);

fillRate = zeros(1,n); 
for i = 1:n
   img = frames(i).z(mask);
   fillRate(i) = sum(img(:)~=0) / numel(img);
end

results.frameFillRate = fillRate(1) * 100;
results.meanFillRate = mean(fillRate) * 100;
results.stdFillRate = std(fillRate) * 100;

score = results.frameFillRate;
results.score = 'frameFillRate';
results.units = 'percentage';
results.error = false;

end

