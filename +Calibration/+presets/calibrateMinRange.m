function [minRangeScaleModRef, maxMod_dec] = calibrateMinRange(hw,calibParams,runParams,fprintff)

%% capture frames
minModprc=0 ;
LaserDelta=2; % decimal
FramesNum=10;

[depthData,LaserPoints,maxMod_dec] = Calibration.presets.captureVsLaserMod(hw,minModprc,LaserDelta,FramesNum);
sz = hw.streamSize;
[minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(depthData,LaserPoints,maxMod_dec,sz,calibParams);
end
