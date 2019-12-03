function [presetCompareRes,frames] = validatePresets( hw, calibParams,runParams, fprintff)
presetCompareRes=[] ;

% set LR preset
hw.setPresetControlState(1);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
hw.shadowUpdate;
        
pause(5);
LRframe=hw.getFrame(calibParams.numOfFrames);
% set SR preset
hw.setPresetControlState(2);
pause(5);
SRframe=hw.getFrame(calibParams.numOfFrames);

hw.setPresetControlState(1);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
hw.shadowUpdate;
%%
frames=[]; 
frames.LRframe=LRframe; 
frames.SRframe=SRframe; 
%% roi 
imgSize = size(LRframe.z);

params = Validation.aux.defaultMetricsParams();
params.mask.rectROI.flag = true;
params.mask.rectROI.allMargins = calibParams.presets.compare.roi;

mask = Validation.aux.getMask(params,'imageSize',imgSize);
%% diff image
z2mm=double(hw.z2mm); 
ZLR=double(frames.LRframe.z)./z2mm;
ZSR=double(frames.SRframe.z)./z2mm;
ZLR(ZLR==0)=nan; ZSR(ZSR==0)=nan; 
LRroi=nan(size(ZLR)); LRroi(mask)=ZLR(mask); 
SRroi=nan(size(ZSR)); SRroi(mask)=ZSR(mask); 

diffImage=LRroi-SRroi; 
presetCompareRes.presetCompareMeanDiff=nanmean(diffImage(:)); 
presetCompareRes.presetCompareStdDiff=nanstd(diffImage(:)); 

ff = Calibration.aux.invisibleFigure();
subplot(1,2,1); imagesc(frames.SRframe.i);colorbar; title('SR ir'); subplot(1,2,2); imagesc(frames.LRframe.i); colorbar; title('LR ir');
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

