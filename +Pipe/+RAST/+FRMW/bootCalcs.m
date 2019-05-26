function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts,regMeta)

%% pre calc


%% prepare for FW

[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(regs,luts,regMeta );
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);
FWinputLuts = Firmware.mergeRegs(FWinputLuts,autogenLuts);


%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts]      = Pipe.RAST.FRMW.fwBootCalcs(FWinputRegs,FWinputLuts,autogenRegs,autogenLuts);
end
