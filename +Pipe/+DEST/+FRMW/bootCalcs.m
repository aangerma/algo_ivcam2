function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

%% pre calc
[PreCalcsRegs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
PreCalcsluts = Firmware.mergeRegs(luts,autogenLuts);

%% prepare for FW

[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(PreCalcsRegs,PreCalcsluts );
regs = Firmware.mergeRegs(regs,FWinputRegs);
luts = Firmware.mergeRegs(luts,FWinputLuts);


%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.fwBootCalcs(regs,luts,autogenRegs,autogenLuts); 

end 