function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)

%% =======================================DIGG - ang2xy- calib res =======================================
[regs,autogenRegs] = ang2xyCoeff(regs,autogenRegs);


%% =======================================DIGG - spherical=======================================
[regs,autogenRegs] = SphericalCoeff(regs,autogenRegs);


%% =======================================DIGG - notch filters=======================================
[regs,autogenRegs] = NotchFilterCoeffs(regs,autogenRegs);


%% =======================================DIGG - undist=======================================

[regs,autogenRegs] = UndistCoeff(regs,luts,autogenRegs);


end





function [regs,autogenRegs] = ang2xyCoeff(regs,autogenRegs)
t = Pipe.DIGG.FRMW.getAng2xyCoeffs(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,t);
regs = Firmware.mergeRegs(regs,autogenRegs);
end


function [regs,autogenRegs] = SphericalCoeff(regs,autogenRegs)

[newRegs] = Pipe.DIGG.FRMW.getSphericalCoeff(regs);

autogenRegs = Firmware.mergeRegs(autogenRegs,newRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);
end

function [regs,autogenRegs] = NotchFilterCoeffs(regs,autogenRegs)

[b,a] = Pipe.DIGG.FRMW.getNotchFilterCoeffs(regs);
avec = typecast(vec(a'),'uint32');
bvec = typecast(vec(b'),'uint32');
for i=1:size(avec,1)
    
    
    
    autogenRegs.DIGG.notchA(i)= (avec(i));
    autogenRegs.DIGG.notchB(i) = (bvec(i));
    
    
end
regs = Firmware.mergeRegs(regs,autogenRegs);

end


function [regs,autogenRegs,autogenLuts] = UndistCoeff(regs,luts,autogenRegs)
autogenRegs.DIGG.undistFx=regs.DIGG.undistFx;
autogenRegs.DIGG.undistFy=regs.DIGG.undistFy;
autogenRegs.DIGG.undistX0=regs.DIGG.undistX0;
autogenRegs.DIGG.undistY0=regs.DIGG.undistY0;
autogenLuts.DIGG.undistModel=luts.DIGG.undistModel; 
regs = Firmware.mergeRegs(regs,autogenRegs);

[ScaleAndShiftRegs] = Pipe.DIGG.FRMW.getUndistScaleAndShift(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,ScaleAndShiftRegs);

regs = Firmware.mergeRegs(regs,autogenRegs);
end