function [maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc_int(maskParams, runParams, calibParams, LongRangestate, totFrames, cameraInput, laserPoints, maxMod_dec, fprintff)
%% Get frames and mask
mask = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams);
%% Define parameters
fillRateTh = calibParams.presets.long.(LongRangestate).fillRateTh; %97;

%% Calculate fill rate
scores = zeros(length(totFrames),1);
oneFrame = struct('i',zeros(cameraInput.imSize(1),cameraInput.imSize(2)),'z',zeros(cameraInput.imSize(1),cameraInput.imSize(2)));
frames = repmat(oneFrame,size(totFrames(1).z,3),1);
for iScenario = 1:length(totFrames)
   for iFrame = 1:size(totFrames(iScenario).z,3)
       frames(iFrame).i = double(totFrames(iScenario).i(:,:,iFrame));
       frames(iFrame).z = double(totFrames(iScenario).z(:,:,iFrame));
       frames(iFrame).i(~mask) = nan;
       frames(iFrame).z(~mask) = nan;
   end
   [scores(iScenario,1), ~, ~] = Validation.metrics.fillRate(frames, maskParams); 
end
maxFillRate = max(scores);

%% Plot
ff1 = Calibration.aux.invisibleFigure;
plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
hold on;
plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); grid minor; hold off;
Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',1,1);
ff1 = Calibration.aux.invisibleFigure;
plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
hold on;
plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); grid minor; hold off;
Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',1,0);
ff2 = Calibration.aux.invisibleFigure;
subplot(2,1,1);imagesc(imfuse(totFrames(end).i(:,:,end),mask));title('IR image with ROI mask');
subplot(2,1,2);imagesc(imfuse(totFrames(end).z(:,:,end),mask));title('Depth (not normalized) image with ROI mask');
Calibration.aux.saveFigureAsImage(ff2,runParams,'Presets','Long_Range_Laser_Calib_mask',1);imagesc(imfuse(frames(1).z,mask));title('Depth (not normalized) image with ROI mask');

%% Find laser scale
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
ix = find(scores >= fillRateTh, 1);
if isempty(ix)
    maxRangeScaleModRef = 1;
    fprintff(['[-] Long range preset calibration: no fill rate found above threshold = ' num2str(fillRateTh) ' %% \n']);
    return;
end
startIx = max(ix-1,1); endIx = min(ix+1,length(scores));
bestIx = startIx:endIx;
[~,ix_min]= min(abs(scores(bestIx) - fillRateTh));
maxRangeScaleModRef = round(laserPoints(bestIx(ix_min)))/maxMod_dec;

%% prepare output script
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
fw = Pipe.loadFirmware(presetPath);
fw.writeDynamicRangeTable(presetsTableFullPath,presetPath);
    

end

