function [regs,autogenRegs,autogenLuts] = newBootCalcs(regs,luts,autogenRegs,autogenLuts)
%% pre calc
% Add if not preCalc bypass here !!!
[preCalcsRegs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
preCalcsLuts = Firmware.mergeRegs(luts,autogenLuts);

%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(preCalcsRegs,preCalcsLuts);
regs = Firmware.mergeRegs(regs,FWinputRegs);
luts = Firmware.mergeRegs(luts,FWinputLuts);

%% Run fw bootcalcs
% Why do we need autogenRegs,autogenLuts here as well?
[regs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.fwBootCalcs(regs,luts,autogenRegs,autogenLuts);

end
