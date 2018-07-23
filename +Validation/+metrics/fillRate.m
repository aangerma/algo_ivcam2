function [score, results] = fillRate(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : struct
%   - roi - regions of interest, percentage [0..1] or [left top width height]


imgSize = size(frames(1).z);

if ~exist('params','var')
    params = struct;
end

mask = Validation.aux.getRoiCircle(imgSize, params);

n = length(frames);

fillRate = zeros(1,n); 
for i = 1:n
   img = frames(i).z(mask);
   fillRate(i) = sum(img(:)~=0) / numel(img);
end

results.frameFillRate = fillRate(1);
results.meanFillRate = mean(fillRate);
results.stdFillRate = std(fillRate);

score = results.frameFillRate;
results.score = 'frameFillRate';
end

