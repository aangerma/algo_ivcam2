function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

%% pre calc
[PreCalasRegs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
PreCalasluts = Firmware.mergeRegs(luts,autogenLuts);

%% write to EPROM

[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(PreCalasRegs,PreCalasluts );
regs = Firmware.mergeRegs(regs,FWinputRegs);
luts = Firmware.mergeRegs(luts,FWinputLuts);


%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.fwBootCalcs(regs,luts,autogenRegs,autogenLuts); 

end 