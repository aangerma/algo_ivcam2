function [autogenRegs,regs] = calculateMargins(regs,autogenRegs)

Hratio=double(regs.GNRL.imgHsize)/double(regs.FRMW.calImgHsize);
Vratio=double(regs.GNRL.imgVsize)/double(regs.FRMW.calImgVsize);
autogenRegs.FRMW.marginL=Hratio*regs.FRMW.calMarginL;
autogenRegs.FRMW.marginR=Hratio*regs.FRMW.calMarginR;
autogenRegs.FRMW.marginB=Vratio*regs.FRMW.calMarginB;
autogenRegs.FRMW.marginT=Vratio*regs.FRMW.calMarginT;
regs = Firmware.mergeRegs(regs,autogenRegs);


end
