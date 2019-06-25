function [maxRangeScaleModRef, maxMod_dec, fillRateAtTargetDist, targetDist] = calibrateLongRange(hw,calibParams,runParams,fprintff)
%% Define parameters
minModprc = calibParams.presets.long.minModprc;%0 ;
laserDelta = calibParams.presets.long.laserDelta;%2; % decimal
framesNum = calibParams.presets.long.framesNum;%10;
cameraInput.z2mm = hw.z2mm;
cameraInput.imSize = double(hw.streamSize);
outDir = fullfile(tempdir,'PresetLongRange');
maskParams = calibParams.presets.long.params;%params.roi = 0.1; params.isRoiRect = 0; params.roiCropRect = 0;


%% Capture frames
[laserPoints,maxMod_dec] = Calibration.presets.captureVsLaserMod(hw,minModprc,laserDelta,framesNum,outDir);

%% Find laser scale
[maxRangeScaleModRef, fillRateAtTargetDist, targetDist] = findScaleByFillRate(maskParams,runParams,calibParams,outDir,cameraInput,laserPoints,maxMod_dec,fprintff);
end

function [maxRangeScaleModRef, fillRateAtTargetDist, targetDist] = findScaleByFillRate(maskParams,runParams,calibParams,inputPath,cameraInput,laserPoints,maxMod_dec,fprintff)
%% Define parameters
fillRateTh = calibParams.presets.long.fillRateTh; %90;
calibTrgetReflect = calibParams.presets.long.calibTargetReflect; % 0.0124
estDistTargetReflect = calibParams.presets.long.estDistTargetReflect; % 0.8

%% Get frames and mask
totFrames = GetLongRangeImages(inputPath,cameraInput.imSize(2),cameraInput.imSize(1));
mask = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams);

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
fillRateAtTargetDist = max(scores);

%% Plot
ff1 = Calibration.aux.invisibleFigure;
plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
hold on;
plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); hold off;
Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',[],1);
ff2 = Calibration.aux.invisibleFigure;
subplot(2,1,1);imagesc(imfuse(totFrames(end).i(:,:,end),mask));title('IR image with ROI mask');
subplot(2,1,2);imagesc(imfuse(totFrames(end).z(:,:,end),mask));title('Depth (not normalized) image with ROI mask');
Calibration.aux.saveFigureAsImage(ff2,runParams,'Presets','Long_Range_Laser_Calib_mask');imagesc(imfuse(frames(1).z,mask));title('Depth (not normalized) image with ROI mask');

%% Find laser scale
zIm = {frames.z};
zIm = cellfun(@(x) x(:)./double(cameraInput.z2mm), zIm,'UniformOutput',false);
zIm_mean = cellfun(@(x) x(x(:)~=0), zIm,'UniformOutput', false);
zIm_mean = cellfun(@nanmean, zIm_mean,'UniformOutput', false);
zIm_mean = nanmean(cell2mat(zIm_mean));
targetDist = zIm_mean*sqrt(estDistTargetReflect/calibTrgetReflect)/1000; %In Meter units
if (targetDist < calibParams.errRange.targetDist(1)) || (targetDist > calibParams.errRange.targetDist(2))
    maxRangeScaleModRef = 1;
    fprintff(['[-] Long range preset calibration: the target is placed in the wrong location. It should match to ' num2str(mean(calibParams.errRange.targetDist)) '[m] but it matches ' num2str(targetDist) ' [m]\n']);  
    fprintff(['[-] Long range preset calibration: actual distance is ' num2str(zIm_mean/1000) ' [m]\n']);  
    return;
end
ix = find(scores >= fillRateTh, 1);
if isempty(ix)
    maxRangeScaleModRef = 1;
    fprintff(['[-] Long range preset calibration: no fill rate found above threshold = ' num2str(fillRateTh) ' %% \n']);
    fprintff(['[-] Long range preset calibration: estimated fill rate at ' num2str(mean(calibParams.errRange.targetDist)) '[m] will be ' num2str(fillRateAtTargetDist) '%% \n']);
    return;
end
maxRangeScaleModRef = round(laserPoints(ix))/maxMod_dec;

%% prepare output script
if calibParams.presets.long.updateCalibVal
    longRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','longRangePreset.csv');
    longRangePreset=readtable(longRangePresetFn);
    modRefInd=find(strcmp(longRangePreset.name,'modulation_ref_factor'));
    longRangePreset.value(modRefInd) = results.maxRangeScaleModRef;
    writetable(longRangePreset,longRangePresetFn);
end
end

function [frames] = GetLongRangeImages(InputPath,width,height)
d = dir(InputPath);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
nameFolds = sort(nameFolds);
for k = 1:numel(nameFolds)
    path = fullfile(InputPath,nameFolds{k});
    frames(k).z = Calibration.aux.GetFramesFromDir(path,width, height,'Z');
    frames(k).i = Calibration.aux.GetFramesFromDir(path,width, height,'I');
end
end
