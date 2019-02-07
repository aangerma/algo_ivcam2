function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
%% pre calc
if regs.FRMW.preCalcBypass
    preCalcsRegs = regs;
    preCalcsLuts = luts;
else
    [preCalcsRegs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    preCalcsLuts = Firmware.mergeRegs(luts,autogenLuts);
end
%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(preCalcsRegs,preCalcsLuts);
regs = Firmware.mergeRegs(regs,FWinputRegs);
luts = Firmware.mergeRegs(luts,FWinputLuts);

%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.fwBootCalcs(regs,luts,autogenRegs,autogenLuts);

end