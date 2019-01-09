function [newRegs] = getSpherialCoeff(regs)
alpha = 2^12/4095*[1-regs.FRMW.xR2L*2 1-regs.FRMW.yflip*2];
% autogenRegs.DIGG.sphericalScale=int16(round(double([regs.FRMW.xres regs.FRMW.yres]).*alpha));
% autogenRegs.DIGG.sphericalOffset=int16(round([double(regs.FRMW.xres)/2-double(regs.FRMW.marginL) double(regs.FRMW.yres)/2-double(regs.FRMW.marginT)].*[4 1]));
newRegs.DIGG.sphericalScale=int16(round(double([regs.GNRL.imgHsize regs.GNRL.imgVsize]).*alpha));
newRegs.DIGG.sphericalOffset=int16(round([double(regs.GNRL.imgHsize)/2 double(regs.GNRL.imgVsize)/2].*[4 1]));
end

