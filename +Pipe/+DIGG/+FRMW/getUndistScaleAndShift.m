function [autogenRegs] = getUndistScaleAndShift(regs)

shift = double(regs.DIGG.bitshift);
toint32 = @(x) int32(x*2^shift);

if(regs.DIGG.undistBypass || (regs.FRMW.undistCalImgHsize==regs.GNRL.imgHsize && regs.FRMW.undistCalImgVsize==regs.GNRL.imgVsize))
    xShiftIn  = 0;
    yShiftIn  = 0;
    xScaleIn  = 1;
    yScaleIn  =1;
    xShiftOut = 0;
    yShiftOut =0;
    xScaleOut = 1;
    yScaleOut = 1;
    
else
    
    xScaleIn=double(regs.GNRL.imgHsize)/double(regs.FRMW.undistCalImgHsize);
    yScaleIn=double(regs.GNRL.imgVsize)/double(regs.FRMW.undistCalImgVsize);
    xShiftIn=0;
    yShiftIn=0;
    xScaleOut=1/xScaleIn;
    yScaleOut=1/yScaleIn;
    xShiftOut=-xShiftIn/xScaleIn;
    yShiftOut=-yShiftIn/yScaleIn;
    
%     [xScaleIn_,yScaleIn_,xShiftIn_,yShiftIn_,xScaleOut_,yScaleOut_,xShiftOut_,yShiftOut_]= CalculateAccurateScaleAndShiftFromAng2XY(regs,shift);
    
end

autogenRegs.DIGG.xShiftIn  = toint32(xShiftIn);
autogenRegs.DIGG.yShiftIn  = toint32(yShiftIn);
autogenRegs.DIGG.xScaleIn  = toint32(xScaleIn);
autogenRegs.DIGG.yScaleIn  = toint32(yScaleIn);
autogenRegs.DIGG.xShiftOut = toint32(xShiftOut);
autogenRegs.DIGG.yShiftOut = toint32(yShiftOut);
autogenRegs.DIGG.xScaleOut = toint32(xScaleOut);
autogenRegs.DIGG.yScaleOut = toint32(yScaleOut);

end

% function [xScaleIn,yScaleIn,xShiftIn,yShiftIn,xScaleOut,yScaleOut,xShiftOut,yShiftOut]= CalculateAccurateScaleAndShiftFromAng2XY(regs,shift)
% % original res - recatangle lut params
% N = 32;%LUT size
% 
% 
% Lut_x0 = double(regs.DIGG.undistX0)/(2^shift);
% Lut_y0 = double(regs.DIGG.undistY0)/(2^shift);
% Lut_fx = double(regs.DIGG.undistFx)/(2^shift);
% Lut_fy = double(regs.DIGG.undistFy)/(2^shift);
% Lut_x1=Lut_x0+(N-1)/Lut_fx;
% Lut_y1=Lut_y0+(N-1)/Lut_fy;
% 
% % current res - recatangle lut params
% 
% [tmpRegs] = Pipe.DIGG.FRMW.calculateAng2xyBlockRec(regs);
% x0 = double(tmpRegs.DIGG.undistX0)/(2^shift);
% y0 = double(tmpRegs.DIGG.undistY0)/(2^shift);
% fx = double(tmpRegs.DIGG.undistFx)/(2^shift);
% fy = double(tmpRegs.DIGG.undistFy)/(2^shift);
% x1=x0+(N-1)/fx;
% y1=y0+(N-1)/fy;
% 
% % calculate scale and offset by block recs
% xScaleIn=(x0-x1)/(Lut_x0-Lut_x1);
% yScaleIn=(y0-y1)/(Lut_y0-Lut_y1);
% xShiftIn=x1-xScaleIn*Lut_x1;
% yShiftIn=y1-yScaleIn*Lut_y1;
% 
% xScaleOut=1/xScaleIn;
% yScaleOut=1/yScaleIn;
% xShiftOut=-xShiftIn/xScaleIn;
% yShiftOut=-yShiftIn/yScaleIn;
% 
% end 