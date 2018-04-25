function [] = hwSetScanDir(hw, dir)

scanDir0gainAddr = '85080000';
scanDir1gainAddr = '85080480';
gainCalibValue  = '000ffff0';

global saveVal;
if isempty(saveVal)
    saveVal(1) = hw.readAddr(scanDir0gainAddr);
    saveVal(2) = hw.readAddr(scanDir1gainAddr);
end

if (dir == 0)
    hw.writeAddr(scanDir0gainAddr,gainCalibValue,true);
    hw.writeAddr(scanDir1gainAddr,uint32(saveVal(2)),true);
elseif (dir == 1)
    hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
    hw.writeAddr(scanDir0gainAddr,uint32(saveVal(1)),true);
elseif (dir == 2)
    hw.writeAddr(scanDir0gainAddr,uint32(saveVal(1)),true);
    hw.writeAddr(scanDir1gainAddr,uint32(saveVal(2)),true);
end

pause(0.2);

end



