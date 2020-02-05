function [isConverged, maxRangeScaleModRef, maxMod_dec, maxFillRate, targetDist] = calibrateLongRange(hw,calibParams,stateName,runParams,fprintff)
%% Define parameters
minModprc = calibParams.presets.long.(stateName).minModprc;%0 ;
laserDelta = calibParams.presets.long.(stateName).laserDelta;%1; % decimal
framesNum = calibParams.presets.long.(stateName).framesNum;%10;
cameraInput.z2mm = hw.z2mm;
cameraInput.imSize = double(hw.streamSize);
maskParams = calibParams.presets.long.params;%params.roi = 0.1; params.isRoiRect = 0; params.roiCropRect = 0; params.maskCenterShift = [0,0];
%% Create Mask
maskParams4user = maskParams;
if isfield(maskParams4user, 'roi')
    maskParams4user.roi = min(maskParams.roi*calibParams.presets.long.mask4userScale,calibParams.presets.long.maxMask4userROI);
end
mask4user = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams4user);
%Calibration.aux.CBTools.showImageRequestDialog(hw,3,diag([1 1 1]),'Long Range Calibration - place black target on center of checkerboard and move camera to end of rail to 800mm and center ROI ',[],uint8(1-mask4user).*uint8(255));
Calibration.aux.changeCameraLocation(hw, true, calibParams.robot.long_preset.type,calibParams.robot.long_preset.dist.(stateName),calibParams.robot.long_preset.ang,calibParams,hw,3,diag([1 1 1]),'Long Range Calibration - place black target on center of checkerboard and move camera to end of rail to 800mm and center ROI ',[],uint8(1-mask4user).*uint8(255));
pause(60);

%% Capture frames
if isfield(calibParams.presets, 'general') && isfield(calibParams.presets.general, 'laserValInPercent')
    laserValInPercent = calibParams.presets.general.laserValInPercent;
else
    laserValInPercent = 0;
end
[frameBytes,laserPoints,maxMod_dec,laserPoint0] = Calibration.presets.captureVsLaserMod(hw,minModprc,laserDelta,framesNum,laserValInPercent);
[isConverged, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(frameBytes,cameraInput,laserPoints,maxMod_dec,laserPoint0,calibParams);
while (isConverged==0)
    Calibration.aux.RegistersReader.setModRef(hw, nextLaserPoint,laserValInPercent);
    frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZI', framesNum);
    [isConverged, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(frameBytes,cameraInput,laserPoints,maxMod_dec,nextLaserPoint,calibParams);
end

end



% function [maxRangeScaleModRef, maxFillRate, targetDist] = findScaleByFillRate(maskParams,runParams,calibParams,inputPath,cameraInput,laserPoints,maxMod_dec,fprintff)
% %% Define parameters
% fillRateTh = calibParams.presets.long.fillRateTh; %97;
%
% %% Get frames and mask
% totFrames = GetLongRangeImages(inputPath,cameraInput.imSize(2),cameraInput.imSize(1));
% mask = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams);
%
% %% Calculate fill rate
% scores = zeros(length(totFrames),1);
% oneFrame = struct('i',zeros(cameraInput.imSize(1),cameraInput.imSize(2)),'z',zeros(cameraInput.imSize(1),cameraInput.imSize(2)));
% frames = repmat(oneFrame,size(totFrames(1).z,3),1);
% for iScenario = 1:length(totFrames)
%    for iFrame = 1:size(totFrames(iScenario).z,3)
%        frames(iFrame).i = double(totFrames(iScenario).i(:,:,iFrame));
%        frames(iFrame).z = double(totFrames(iScenario).z(:,:,iFrame));
%        frames(iFrame).i(~mask) = nan;
%        frames(iFrame).z(~mask) = nan;
%    end
%    [scores(iScenario,1), ~, ~] = Validation.metrics.fillRate(frames, maskParams); 
% end
% maxFillRate = max(scores);
% 
% %% Plot
% ff1 = Calibration.aux.invisibleFigure;
% plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
% hold on;
% plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); grid minor; hold off;
% Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',[],1);
% ff1 = Calibration.aux.invisibleFigure;
% plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
% hold on;
% plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); grid minor; hold off;
% Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',[],0);
% ff2 = Calibration.aux.invisibleFigure;
% subplot(2,1,1);imagesc(imfuse(totFrames(end).i(:,:,end),mask));title('IR image with ROI mask');
% subplot(2,1,2);imagesc(imfuse(totFrames(end).z(:,:,end),mask));title('Depth (not normalized) image with ROI mask');
% Calibration.aux.saveFigureAsImage(ff2,runParams,'Presets','Long_Range_Laser_Calib_mask');imagesc(imfuse(frames(1).z,mask));title('Depth (not normalized) image with ROI mask');
% 
% %% Find laser scale
% zIm = {frames.z};
% zIm = cellfun(@(x) x(:)./double(cameraInput.z2mm), zIm,'UniformOutput',false);
% zIm_mean = cellfun(@(x) x(x(:)~=0), zIm,'UniformOutput', false);
% zIm_mean = cellfun(@nanmean, zIm_mean,'UniformOutput', false);
% zIm_mean = nanmean(cell2mat(zIm_mean));
% targetDist = zIm_mean; %In mm units
% if (targetDist < calibParams.errRange.targetDist(1)) || (targetDist > calibParams.errRange.targetDist(2))
%     maxRangeScaleModRef = 1;
%     fprintff(['[-] Long range preset calibration: the target is placed in the wrong location. It should be at ' num2str(mean(calibParams.errRange.targetDist)) '[mm] but it is at ' num2str(targetDist) ' [mm]. Modulation ref will remain at max value\n']);  
%     return;
% end
% ix = find(scores >= fillRateTh, 1);
% if isempty(ix)
%     maxRangeScaleModRef = 1;
%     fprintff(['[-] Long range preset calibration: no fill rate found above threshold = ' num2str(fillRateTh) ' %% \n']);
%     return;
% end
% startIx = max(ix-1,1); endIx = min(ix+1,length(scores));
% bestIx = startIx:endIx;
% [~,ix_min]= min(abs(scores(bestIx) - fillRateTh));
% maxRangeScaleModRef = round(laserPoints(bestIx(ix_min)))/maxMod_dec;
% 
% %% prepare output script
% if calibParams.presets.long.updateCalibVal
%     longRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','longRangePreset.csv');
%     longRangePreset=readtable(longRangePresetFn);
%     modRefInd=find(strcmp(longRangePreset.name,'modulation_ref_factor'));
%     longRangePreset.value(modRefInd) = maxRangeScaleModRef;
%     writetable(longRangePreset,longRangePresetFn);
% end
% end
% 
% function [frames] = GetLongRangeImages(InputPath,width,height)
% d = dir(InputPath);
% isub = [d(:).isdir]; %# returns logical vector
% nameFolds = {d(isub).name}';
% nameFolds(ismember(nameFolds,{'.','..'})) = [];
% nameFolds = sort(nameFolds);
% for k = 1:numel(nameFolds)
%     path = fullfile(InputPath,nameFolds{k});
%     frames(k).z = Calibration.aux.GetFramesFromDir(path,width, height,'Z');
%     frames(k).i = Calibration.aux.GetFramesFromDir(path,width, height,'I');
% end
% end
