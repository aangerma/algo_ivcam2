function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts,regMeta)
%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(regs,luts,regMeta);
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);

%% Run fw bootcalcs
[regs,autogenRegs] = Pipe.INFC.FRMW.fwBootCalcs(FWinputRegs,autogenRegs);

end

