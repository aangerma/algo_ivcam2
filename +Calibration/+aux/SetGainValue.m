function [] = SetGainValue(hw,Val1, Val2)
    scanDir1gainAddr = '85080000';
    scanDir2gainAddr = '85080480';
    hw.writeAddr(scanDir1gainAddr,Val1,true);
    hw.writeAddr(scanDir2gainAddr,Val2,true);
    pause(0.1);
end
