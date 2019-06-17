function [presetCompareRes,frames] = validatePresets( hw, calibParams,runParams, fprintff)
presetCompareRes=[] ;

% set LR preset
hw.setPresetControlState(1);
pause(2);
LRframe=hw.getFrame(calibParams.numOfFrames);
% set SR preset
hw.setPresetControlState(2);
pause(2);
SRframe=hw.getFrame(calibParams.numOfFrames);

hw.setPresetControlState(1);

%%
frames=[]; 
frames.LRframe=LRframe; 
frames.SRframe=SRframe; 

%% roi 

imgSize = size(LRframe.z);

params = Validation.aux.defaultMetricsParams();
params.roi=calibParams.roi; params.isRoiRect=1; 
mask = Validation.aux.getRoiMask(imgSize, params);

%% diff image
z2mm=double(hw.z2mm); 
ZLR=double(LRframe.z)./z2mm;
ZSR=double(SRframe.z)./z2mm;
ZLR(ZLR==0)=nan; ZSR(ZSR==0)=nan; 
LRroi=nan(size(ZLR)); LRroi(mask)=ZLR(mask); 
SRroi=nan(size(ZSR)); SRroi(mask)=ZSR(mask); 

diffImage=LRroi-SRroi; 
presetCompareRes.presetCompareMeanDiff=nanmean(diffImage(:)); 
presetCompareRes.presetCompareStdDiff=nanstd(diffImage(:)); 

ff = Calibration.aux.invisibleFigure();
subplot(1,2,1); imagesc(SRframe.i);colorbar; title('SR ir'); subplot(1,2,2); imagesc(LRframe.i); colorbar; title('LR ir');
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','IR_PresetsComparison',1);

ff = Calibration.aux.invisibleFigure();
subplot(1,2,1); imagesc(ZSR);colorbar; title('SR z');caxis([prctile(ZSR(:),2),prctile(ZSR(:),98)]);
subplot(1,2,2); imagesc(ZLR); colorbar; title('LR z');caxis([prctile(ZSR(:),2),prctile(ZSR(:),98)]);
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Z_PresetsComparison',1);


ff = Calibration.aux.invisibleFigure();
fullDiff=ZLR-ZSR;
imagesc(fullDiff);colormap jet;colorbar;
title(sprintf(['presets comparison: LRframe.z-SRframe.z , mean diff [mm] on roi ',num2str(calibParams.roi*100) ,' = ' ,num2str(presetCompareRes.presetCompareMeanDiff)]  ));
caxis([prctile(fullDiff(:),2),prctile(fullDiff(:),98)]);
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','DiffZ_PresetsComparison',1);


end
%

