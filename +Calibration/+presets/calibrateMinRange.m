function [isConverged, minRangeScaleModRef, maxMod_dec] = calibrateMinRange(hw,calibParams,runParams,fprintff)

%% capture frames
minModprc=0 ;
LaserDelta=2; % decimal
framesNum=10;
if isfield(calibParams.presets, 'general') && isfield(calibParams.presets.general, 'laserValInPercent')
    laserValInPercent = calibParams.presets.general.laserValInPercent;
else
    laserValInPercent = 0;
end
[frameBytes,LaserPoints,maxMod_dec,laserPoint0] = Calibration.presets.captureVsLaserMod(hw,minModprc,LaserDelta,framesNum,laserValInPercent);
sz = hw.streamSize;
[isConverged, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(frameBytes,LaserPoints,maxMod_dec,laserPoint0,sz,calibParams);
while (isConverged==0)
    Calibration.aux.RegistersReader.setModRef(hw, nextLaserPoint,laserValInPercent);
    frameBytes = Calibration.aux.captureFramesWrapper(hw, 'I', framesNum);
    [isConverged, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(frameBytes,LaserPoints,maxMod_dec,nextLaserPoint,sz,calibParams);
end
end
