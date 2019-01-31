function [ xZO,yZO ] = zoLoc( fw ,calibParams)
%ZOLOC calculates the location of the ZO pixel (in the users rectified
%image).
FE = [];
if calibParams.fovExpander.valid
    FE = calibParams.fovExpander.table;
end

regs = fw.get();
[xZO,yZO] = Calibration.aux.ang2xySF(0,0,regs,FE,1); % ZO location
xZO = regs.GNRL.imgHsize - uint16(xZO);
yZO = regs.GNRL.imgVsize - uint16(yZO);


end

