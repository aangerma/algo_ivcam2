function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)

%=======================================DIGG - ang2xy- calib res =======================================
t = Pipe.DIGG.FRMW.getAng2xyCoeffs(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,t);
regs = Firmware.mergeRegs(regs,autogenRegs);

%=======================================DIGG - spherical=======================================
 
[newRegs] = Pipe.DIGG.FRMW.getSphericalCoeff(regs);

autogenRegs = Firmware.mergeRegs(autogenRegs,newRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);
%=======================================DIGG - notch filters=======================================

[b,a] = Pipe.DIGG.FRMW.getNotchFilterCoeffs(regs);
avec = typecast(vec(a'),'uint32');
bvec = typecast(vec(b'),'uint32');
for i=1:size(avec,1)
    

    
    autogenRegs.DIGG.notchA(i)= (avec(i));
    autogenRegs.DIGG.notchB(i) = (bvec(i));

    
end
%=======================================DIGG - undist=======================================
autogenRegs.DIGG.undistFx=regs.DIGG.undistFx;
autogenRegs.DIGG.undistFy=regs.DIGG.undistFy;
autogenRegs.DIGG.undistX0=regs.DIGG.undistX0;
autogenRegs.DIGG.undistY0=regs.DIGG.undistY0;
regs = Firmware.mergeRegs(regs,autogenRegs);

[ScaleAndShiftRegs] = Pipe.DIGG.FRMW.getUndistScaleAndShift(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,ScaleAndShiftRegs);





regs = Firmware.mergeRegs(regs,autogenRegs);

end

