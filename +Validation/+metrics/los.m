function [score, results] = los(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : defined as in aux.defaultMetricsParams

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

[gridPoints, gridSize] = Validation.aux.findCheckerboard(frames(1).i, []);
if (isempty(gridPoints))
    if (params.verbose)
        warning('los: grid is not detected');
    end
    score = nan;
    results.error = true;
    return;
end

points = zeros([size(gridPoints) n]);

%% find grid points for all the images
for i = 1:n
    ir = frames(i).i;
    [gridPoints, gsz] = Validation.aux.findCheckerboard(ir, []);
    
    if (params.verbose)
        fig = figure(17); imagesc(ir); hold on;
        plot(gridPoints(:,1), gridPoints(:,2), '+r');
        title(sprintf('grid for frame %g', i));
    end
    
    if (isempty(gridPoints) || ~isequal(gsz, gridSize))
        if (params.verbose)
            warning('los: grid does not match the first detected grid');
            close(fig);
        end
        score = nan;
        results.error = true;
        return;
    end

    points(:,:,i) = gridPoints;
end

if (params.verbose)
    close(fig);
end

%% estimate results

% figure; plot(squeeze(points(:,1,:))', squeeze(points(:,2,:))')
% figure; imagesc(ir); hold on; plot(pMean(:,1), pMean(:,2), '+r');

pStd = std(points, 0, 3);
pMean = mean(points, 3);

results.meanStdX = mean(pStd(:,1));
results.meanStdY = mean(pStd(:,2));

driftX = sum(diff(squeeze(points(:,1,:)), 1, 2),2);
driftY = sum(diff(squeeze(points(:,2,:)), 1, 2),2);

results.driftX = mean(driftX);
results.driftY = mean(driftY);

results.absDriftX = mean(abs(driftX));
results.absDriftY = mean(abs(driftY));

score = results.meanStdX;
results.score = 'meanStdX';
results.error = false;

end

