function [minRangeScaleModRef, ModRefDec] = calibrateMinRange(hw,calibParams,runParams,fprintff)
%% capture frames
minModprc=0 ;
LaserDelta=2; % decimal
FramesNum=10;
outDir = fullfile(ivcam2tempdir,'PresetMinRange');
[LaserPoints,maxMod_dec,~] = Calibration.presets.captureVsLaserMod(hw,minModprc,LaserDelta,FramesNum,true,outDir);
 sz = hw.streamSize;
[minRangeScaleModRef, ModRefDec] = Preset_Calib_Calc(outDir,LaserPoints,maxMod_dec,sz,calibParams);
end
