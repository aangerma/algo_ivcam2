function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)


%% pre calc


%% prepare for FW

[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(regs,luts );
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);
FWinputLuts = Firmware.mergeRegs(FWinputLuts,autogenLuts);

%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts]      = Pipe.DCOR.FRMW.fwBootCalcs(FWinputRegs,FWinputLuts,autogenRegs,autogenLuts);
end
