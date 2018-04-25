function [frame1, frame2] = getFrameTwoDirs(hw, nFrames)

if ~exist('nFrames', 'var')
    nFrames = 1;
end

scanDir1gainAddr = '85080000';
scanDir2gainAddr = '85080480';
gainCalibValue  = '000ffff0';

saveVal(1) = hw.readAddr(scanDir1gainAddr);
saveVal(2) = hw.readAddr(scanDir2gainAddr);

hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
pause(0.15);

frame1 = hw.getFrame(nFrames);

hw.writeAddr(scanDir1gainAddr,saveVal(1),true);
hw.writeAddr(scanDir2gainAddr,gainCalibValue,true);
pause(0.15);

frame2 = hw.getFrame(nFrames);

hw.writeAddr(scanDir2gainAddr,saveVal(2),true);
pause(0.1);

end


