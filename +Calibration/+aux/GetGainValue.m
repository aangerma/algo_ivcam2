function [Val1, Val2] = GetGainValue(hw)
    scanDir1gainAddr = '85080000';
    scanDir2gainAddr = '85080480';
    Val1 =hw.readAddr(scanDir1gainAddr);
    Val2 =hw.readAddr(scanDir2gainAddr);
end
