function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,~,autogenRegs,autogenLuts)

xr = double(regs.FRMW.xres);
yr = double(regs.FRMW.yres);
xroi = double(regs.GNRL.imgHsize);
yroi = double(regs.GNRL.imgVsize);
if(~regs.JFIL.upscalexyBypass && regs.JFIL.upscalex1y0==1)
    xroi=xroi*2;
elseif(~regs.JFIL.upscalexyBypass && regs.JFIL.upscalex1y0==0)
    yroi=yroi*2;
end

% autogenRegs.PCKR.padding = uint32(xr*yr-xroi*yroi);
autogenRegs.PCKR.padding = uint32(0);
regs = Firmware.mergeRegs(regs,autogenRegs);
end

