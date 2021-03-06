function [frameBytes,LaserPoints,maxMod_dec,laserPoint0] = captureVsLaserMod(hw,minModprc,laserDelta,framesNum,laserValInPercent)
% minModprc=percent from max to be minimum value,  laserDelta=laser loop
% interval (decimal)
%% read max modulation
s=hw.cmd('irb e2 09 01');
max_hex = sscanf(s,'Address: %*s => %s');
maxMod_dec = hex2dec(max_hex);

startPoint=round(minModprc*maxMod_dec);
LaserPoints=[startPoint:laserDelta:maxMod_dec];
if (LaserPoints(end)~=maxMod_dec)
    LaserPoints(end+1)=maxMod_dec;
end
if exist('laserValInPercent','var') && laserValInPercent
    if laserValInPercent
        LaserPoints = round(LaserPoints./maxMod_dec * 100);
    else
        laserValInPercent = 0;
    end
end

%% capture with maximal mod ref as an initial guess
hw.getFrame(framesNum,false); 
laserPoint0 = max(LaserPoints);
Calibration.aux.RegistersReader.setModRef(hw, laserPoint0,laserValInPercent);
frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZI', framesNum);

end

