function [score, results] = losGridDrift(frames, params)

% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : defined as in aux.defaultMetricsParams

imgSize = size(frames(1).z);

if ~exist('params','var')
    params = Validation.aux.defaultMetricsParams();
end

n = length(frames);

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
        plot(gridPoints(:,1), gridPoints(:,2), '+r'); hold off;
        title(sprintf('grid for frame %g', i));
    end
    
    if (isempty(gridPoints) || ~isequal(gsz, gridSize))
        if (params.verbose)
            warning('los: grid %g does not match the first detected grid', i);
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

nPoints = size(points,1);

pXFits = cell2mat(arrayfun(@(p) polyfit(1:n,squeeze(points(p,1,:))',1),1:nPoints, 'UniformOutput',false)');
pYFits = cell2mat(arrayfun(@(p) polyfit(1:n,squeeze(points(p,2,:))',1),1:nPoints, 'UniformOutput',false)');

pX0 = arrayfun(@(p) polyval(pXFits(p,:),1),1:nPoints);
pX1 = arrayfun(@(p) polyval(pXFits(p,:),n),1:nPoints);
driftX = pX1 - pX0;

pY0 = arrayfun(@(p) polyval(pYFits(p,:),1),1:nPoints);
pY1 = arrayfun(@(p) polyval(pYFits(p,:),n),1:nPoints);
driftY = pY1 - pY0;


if (params.verbose)
    figure; imagesc(reshape(driftX,gridSize)); title('Drift X');
    figure; imagesc(reshape(driftY,gridSize)); title('Drift Y');
end

pStd = std(points, 0, 3);

results.meanStdX = mean(pStd(:,1));
results.meanStdY = mean(pStd(:,2));

results.meanDriftX = mean(abs(driftX));
results.meanDriftY = mean(abs(driftY));

results.maxDriftX = max(abs(driftX));
results.maxDriftY = max(abs(driftY));

results.maxDrift = max(results.maxDriftX, results.maxDriftY);
results.stability = min(1/max(eps, results.maxDrift),1000);

score = results.stability;
results.score = 'stability';
results.units = '1/pixels';
results.error = false;

end

