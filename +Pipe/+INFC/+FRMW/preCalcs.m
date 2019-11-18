function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)


%% zero order location
%ZOLOC calculates the location of the ZO pixel (in the users rectified
%image).
regs.DIGG.bitshift = uint8(15);
[xPreUndist,yPreUndist] = Calibration.aux.ang2xySF(0,0,regs);
[ xnew,ynew ] = Pipe.DIGG.undist( xPreUndist*2^15,yPreUndist*2^15,regs,autogenLuts,[],[] );
autogenRegs.FRMW.zoRawCol(1:5) = uint32(single(xnew)/2^15 + 0.5); % 0.5 is here bacause the center of the first pixel, zoRawCol 
autogenRegs.FRMW.zoRawRow(1:5) = uint32(single(ynew)/2^15 + 0.5);



%%
regs = Firmware.mergeRegs(regs,autogenRegs);
end