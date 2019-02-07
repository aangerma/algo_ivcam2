function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(regs,luts);
regs = Firmware.mergeRegs(regs,FWinputRegs);
luts = Firmware.mergeRegs(luts,FWinputLuts);

%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.PCKR.FRMW.fwBootCalcs(regs,luts,autogenRegs,autogenLuts);

end

