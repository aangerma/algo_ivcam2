function [maxRangeScaleModRef, results] = calibrateMaxRange(hw,calibParams,runParams,fprintff)
%% capture frames
minModprc=0 ;
LaserDelta=2; % decimal
FramesNum=10;

[LaserPoints,maxMod_dec,frames] = Calibration.presets.captureVsLaserMod(hw,minModprc,LaserDelta,FramesNum,false);


%% create mask on low laser
margins=[2,2]; 
[blackMask,whiteMask]=Calibration.aux.CBTools.CreateMaskOfSq(irImage,margins); 
end

