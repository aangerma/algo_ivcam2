function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)

%% =======================================DIGG - ang2xy- calib res =======================================
% Ang2xy is the transformation from angular data to rasterized grid over the projected plane.
%  The calculations produces:
%  *18 floating point coefficients for the runtime calculations (DIGG: nx,dx,ny,dy.)
%  *4 output registers for other blocks in the pipe: DIGG.angXfactor, DIGG.angYfactor.
% parameters for firmware to save: FRMW.xres,FRMW.yres,FRMW.marginL/R/T/B .
% Ang2xyCoeff function should be calculated when one of the following is changing: 
% Regs from EPROM: regs.FRMW.xfov, regs.FRMW.yfov, regs.FRMW.laserangleH,regs.FRMW.laserangleV,regs.FRMW.marginL/R/T/B, regs.FRMW.guardBandH,regs.FRMW.guardBandV, regs.FRMW.xR2L,regs.FRMW.xoffset, regs.FRMW.yoffset
%  Regs from external configuration: regs.GNRL.rangeFinder,regs.FRMW.mirrorMovmentMode, regs.FRMW.calMarginL/R/T/B, regs.FRMW.yflip,regs.GNRL.imgHsize,regs.GNRL.imgVsize  

[regs,autogenRegs] = ang2xyCoeff(regs,autogenRegs);


%% =======================================DIGG - spherical=======================================
% Calculating scale and shift for spherical mode. 
% The calculations produces:
% 2 output registers: DIGG.sphericalScale, DIGG.sphericalOffset
% SphericalCoeff function should be calculated when one of the following is changing: 
% Regs from EPROM:regs.FRMW.xR2L
%  Regs from external configuration:regs.FRMW.yflip,regs.GNRL.imgHsize,regs.GNRL.imgVsize

[regs,autogenRegs] = SphericalCoeff(regs,autogenRegs);


%% =======================================DIGG - notch filters=======================================
% Calculating coefficients for notch filters. 
% The calculations produces:DIGG.notchA, DIGG.notchB (coefficients vectors)
% NotchFilterCoeffs function should be calculated when one of the following is changing: 
% Regs from EPROM:regs.GNRL.codeLength, regs.FRMW.notchBw0, regs.FRMW.notchBwDecay
%  Regs from external configuration:regs.GNRL.sampleRate

[regs,autogenRegs] = NotchFilterCoeffs(regs,autogenRegs);


%% =======================================DIGG - undist=======================================
% Calculating coefficients for using Undist Lut 
% The function produces:
% copy from EPROM: REGS: DIGG.undistFx,DIGG.undistFy,DIGG.undistX0,DIGG.undistY0,LUTS: DIGG.undistModel; 
% and calculating:
% DIGG.xShiftIn,DIGG.yShiftIn,DIGG.xScaleIn,DIGG.yScaleIn,DIGG.xShiftOut,DIGG.yShiftOut,DIGG.xScaleOut,DIGG.yScaleOut
% UndistCoeff function should be calculated when one of the following is changing: 
% Regs from EPROM:regs.DIGG.bitshift, regs.FRMW.undistCalImgHsize,regs.FRMW.undistCalImgVsize
%  Regs from external configuration:regs.DIGG.undistBypass,regs.GNRL.imgHsize, regs.GNRL.imgVsize

[regs,autogenRegs] = UndistCoeff(regs,luts,autogenRegs);


end





function [regs,autogenRegs] = ang2xyCoeff(regs,autogenRegs)
% update margins
[autogenRegs,regs] =Pipe.DIGG.FRMW.calculateMargins(regs,autogenRegs);
% ang2xy coeff
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