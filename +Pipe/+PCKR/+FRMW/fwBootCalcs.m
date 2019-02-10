function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates the number of pixel zero padding that will be added to the end of the column stack image 
% -----------------------------------
% Regs from external configuration:
% -----------------------------------
% regs.GNRL.imgHsize, regs.GNRL.imgVsize, regs.PCKR.externalHsize,regs.PCKR.externalVsize 
% regs.JFIL.upscalexyBypass, regs.JFIL.upscalex1y
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xr = single(regs.PCKR.externalHsize);
yr = single(regs.PCKR.externalVsize);
xroi = double(regs.GNRL.imgHsize);
yroi = double(regs.GNRL.imgVsize);
if(~regs.JFIL.upscalexyBypass && regs.JFIL.upscalex1y0==1)
    xroi=xroi*2;
elseif(~regs.JFIL.upscalexyBypass && regs.JFIL.upscalex1y0==0)
    yroi=yroi*2;
end

autogenRegs.PCKR.padding = uint32(xr*yr-xroi*yroi);
regs = Firmware.mergeRegs(regs,autogenRegs);
end

