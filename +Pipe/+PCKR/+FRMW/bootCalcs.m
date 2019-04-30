function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(regs,luts);
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);
FWinputLuts = Firmware.mergeRegs(FWinputLuts,autogenLuts);

%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.PCKR.FRMW.fwBootCalcs(FWinputRegs,FWinputLuts,autogenRegs,autogenLuts);

end

