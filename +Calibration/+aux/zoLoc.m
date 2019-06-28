function [ xZO,yZO ] = zoLoc( fw )
%ZOLOC calculates the location of the ZO pixel (in the users rectified
%image).

regs = fw.get();
[xZO,yZO] = Calibration.aux.vec2xy(Calibration.aux.ang2vec(0,0,regs), regs); % ZO location
xZO = regs.GNRL.imgHsize - uint16(xZO);
yZO = regs.GNRL.imgVsize - uint16(yZO);


end

