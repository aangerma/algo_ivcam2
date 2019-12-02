function [isConverged, curScore, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc_int(maskParams, runParams, calibParams, LongRangestate, im, cameraInput, laserPoints, maxMod_dec, testedPoints, testedScores, fprintff)

% mask = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams);
fillRateTh = calibParams.presets.long.(LongRangestate).fillRateTh; %97;
guessOnInterval = calibParams.presets.long.(LongRangestate).guessOnInterval;

% Calculate fill rate
oneFrame = struct('i',zeros(cameraInput.imSize(1),cameraInput.imSize(2)),'z',zeros(cameraInput.imSize(1),cameraInput.imSize(2)));
frames = repmat(oneFrame,size(im.z,3),1);
for iFrame = 1:size(im.z,3)
    frames(iFrame).i = double(im.i(:,:,iFrame));
    frames(iFrame).z = double(im.z(:,:,iFrame));
%     frames(iFrame).i(~mask) = nan;
%     frames(iFrame).z(~mask) = nan;
end

calibParams.mask.rectROI.flag = false;
calibParams.mask.circROI.flag = true;
calibParams.mask.checkerBoard.flag = false;
calibParams.mask.detectDarkRect.flag = false;
calibParams.presets.long.params.roi;
calibParams.mask.circROI.radius = calibParams.presets.long.params.roi;
mask = Validation.aux.getMask(calibParams,frames(1)); 

[curScore, ~, ~] = Validation.metrics.zFillRate(frames, calibParams);
testedScores(end) = curScore;

% Plot at best fill rate
if (length(testedScores)==1)
    ff2 = Calibration.aux.invisibleFigure;
    subplot(2,1,1);imagesc(imfuse(im.i(:,:,end),mask));title('IR image with ROI mask');
    subplot(2,1,2);imagesc(imfuse(im.z(:,:,end),mask));title('Depth (not normalized) image with ROI mask');
    Calibration.aux.saveFigureAsImage(ff2,runParams,'Presets','Long_Range_Laser_Calib_mask',1);%imagesc(imfuse(frames(1).z,mask));title('Depth (not normalized) image with ROI mask');
end

% convergence check
[isConverged, nextLaserPoint] = chooseNextLaserPoint(laserPoints, testedPoints, testedScores, fillRateTh, guessOnInterval);
if (isConverged==0) % wait for next iteration
    maxRangeScaleModRef = NaN;
    maxFillRate = NaN;
    targetDist = NaN;
    return
end

% Plot at last iteration
if ~isempty(runParams)
    [sortedPoints, sortIdcs] = sort(testedPoints);
    sortedScores = testedScores(sortIdcs);
    ff1 = Calibration.aux.invisibleFigure;
    hold on;
    plot(testedPoints, testedScores, '--o'); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
    plot(sortedPoints, sortedScores, 'c--')
    plot(testedPoints, repelem(fillRateTh,length(testedPoints)), 'r'); grid minor; hold off;
    Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',1,1);
    ff1 = Calibration.aux.invisibleFigure;
    hold on;
    plot(testedPoints,testedScores, '--o'); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
    plot(sortedPoints, sortedScores, 'c--')
    plot(testedPoints, repelem(fillRateTh,length(testedPoints)), 'r'); grid minor; hold off;
    Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',1,0);
end

% convergence check
if (isConverged==-1) % fatal error
    if (nextLaserPoint==Inf)
        fprintff('[!] Long range preset calibration: Fill rate threshold could not be attained. Modulation ref set to 1.\n')
        maxRangeScaleModRef = 1;
    elseif (nextLaserPoint==-Inf)
        fprintff('[!] Long range preset calibration: Fill rate threshold is always exceeded. Modulation ref set to 0.\n')
        maxRangeScaleModRef = 0;
    end
    maxFillRate = max(testedScores);
    targetDist = NaN;
    return
end

%% convergence achieved - proceed to final operations
maxFillRate = max(testedScores);

% analyze target distance
zIm = {frames.z};
zIm = cellfun(@(x) x(:)./double(cameraInput.z2mm), zIm,'UniformOutput',false);
zIm_mean = cellfun(@(x) x(x(:)~=0), zIm,'UniformOutput', false);
zIm_mean = cellfun(@nanmean, zIm_mean,'UniformOutput', false);
zIm_mean = nanmean(cell2mat(zIm_mean));
targetDist = zIm_mean; %In mm units
if (targetDist < calibParams.errRange.(['targetDist_',LongRangestate])(1)) || (targetDist > calibParams.errRange.(['targetDist_',LongRangestate])(2))
    maxRangeScaleModRef = 1;
    fprintff(['[-] Long range preset calibration: the target is placed in the wrong location. It should be at ' num2str(mean(calibParams.errRange.(['targetDist_',LongRangestate]))) '[mm] but it is at ' num2str(targetDist) ' [mm]. Modulation ref will remain at max value\n']);  
    return;
end

% Find laser scale
[testedScores, sortIdcs] = sort(testedScores, 'ascend');
testedPoints = testedPoints(sortIdcs);
ix = find(testedScores >= fillRateTh, 1, 'first'); % always non-empty
startIx = max(ix-1,1); endIx = min(ix+1,length(testedScores));
bestIx = startIx:endIx;
[~,ix_min]= min(abs(testedScores(bestIx) - fillRateTh));
maxRangeScaleModRef = round(testedPoints(bestIx(ix_min)))/maxMod_dec;

% prepare output script
if calibParams.presets.long.updateCalibVal
    longRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','longRangePreset.csv');
    longRangePreset=readtable(longRangePresetFn);
    modRefInd=find(strcmp(longRangePreset.name,calibParams.presets.long.(LongRangestate).ModRefPresetState));
    longRangePreset.value(modRefInd) = maxRangeScaleModRef;
    writetable(longRangePreset,longRangePresetFn);
end
presetPath = fullfile(runParams.outputFolder,'AlgoInternal');
presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
presetsTableFullPath = fullfile(runParams.outputFolder,'calibOutputFiles', presetsTableFileName);

initFolder = presetPath;
fw = Pipe.loadFirmware(initFolder,'tablesFolder',initFolder);
fw.writeDynamicRangeTable(presetsTableFullPath,presetPath);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [isConverged, nextLaserPoint] = chooseNextLaserPoint(laserPoints, testedPoints, testedScores, fillRateTh, guessOnInterval)
% initialization
isConverged = 0;
nextLaserPoint = NaN;
% trivial stop condition
availablePoints = setdiff(laserPoints, testedPoints);
if isempty(availablePoints)
    isConverged = 1;
    return
end
% choosing next point
if (length(testedPoints)==1) % choose another point on search region boundary
    if (testedPoints < max(laserPoints))
        nextLaserPoint = max(laserPoints); % maximal fill rate must be attained once
    else
        nextLaserPoint = min(laserPoints);
    end
else % 2 tested points or more
    [testedScores, sortIdcs] = sort(testedScores, 'ascend');
    testedPoints = testedPoints(sortIdcs);
    indAbove = find(testedScores >= fillRateTh, 1, 'first');
    indBelow = find(testedScores < fillRateTh, 1, 'last');
    if isempty(indAbove) % threshold cannot be attained
        isConverged = -1;
        nextLaserPoint = Inf; % indicating we would wish for a larger mod ref
        return
    end
    if isempty(indBelow)
        if (min(testedPoints) <= min(availablePoints)) % threshold will always be exceeded
            isConverged = -1;
            nextLaserPoint = -Inf; % indicating we would wish for a smaller mod ref
            return
        else % lower limit somehow wasn't chosen yet
            nextLaserPoint = min(availablePoints);
            return
        end
    end
    % apply binary search (with possible bias)
    searchIdcs = find(availablePoints > testedPoints(indBelow) & availablePoints < testedPoints(indAbove));
    if isempty(searchIdcs) % further optimization is beyond laser points resolution
        isConverged = 1;
    else
        ind = round(length(searchIdcs)*guessOnInterval); % guessOnInterval = fraction along [0,1] of next guess
        ind = max(1, min(length(searchIdcs), ind));
        nextLaserPoint = availablePoints(searchIdcs(ind));
    end
end

end
