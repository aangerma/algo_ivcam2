function [score, results] = planeFit(frames, params)

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

%Z = cat(3, frames.z);
%Z(Z==0) = nan;
%Z = nanmean(Z, 3);

for i = 1:n
    Z = frames(i).z;

    v = Validation.aux.imgToVertices(Z, params.camera.K, mask);
    x = v(:,1);
    y = v(:,2);
    z = v(:,3);
    
    % plane fit
    A = [x y ones(length(x),1)];
    p = (A'*A)\(A'*z);
    zf = x*p(1)+y*p(2)+p(3);
    
    dist = abs(z-zf);
    
    rmsPlaneFitDist(i) = rms(dist);
    maxPlaneFitDist(i) = max(dist);
end

results.rmsPlaneFitDist = mean(rmsPlaneFitDist);
results.maxPlaneFitDist = mean(maxPlaneFitDist);

score = results.rmsPlaneFitDist;
results.score = 'rmsPlaneFitDist';
results.units = 'mm';
results.error = false;

end



