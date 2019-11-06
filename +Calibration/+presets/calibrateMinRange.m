function [isConverged, minRangeScaleModRef, maxMod_dec] = calibrateMinRange(hw,calibParams,runParams,fprintff)

%% capture frames
minModprc=0 ;
LaserDelta=2; % decimal
FramesNum=10;

[depthData,LaserPoints,maxMod_dec,laserPoint0] = Calibration.presets.captureVsLaserMod(hw,minModprc,LaserDelta,FramesNum);
sz = hw.streamSize;
[isConverged, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(depthData,LaserPoints,maxMod_dec,laserPoint0,sz,calibParams);
while (isConverged==0)
    Calibration.aux.RegistersReader.setModRef(hw, nextLaserPoint);
    depthData = Calibration.aux.captureFramesWrapper(hw, 'I', framesNum);
    [isConverged, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(depthData,LaserPoints,maxMod_dec,nextLaserPoint,sz,calibParams);
end
end
