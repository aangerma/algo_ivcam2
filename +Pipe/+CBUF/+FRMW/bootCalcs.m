function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
%% pre calc
if regs.FRMW.preCalcBypass
    preCalcsRegs = regs;
    preCalcsLuts = luts;
else
    [preCalcsRegs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    preCalcsLuts = Firmware.mergeRegs(luts,autogenLuts);
end

%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(preCalcsRegs,preCalcsLuts);
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);
FWinputLuts = Firmware.mergeRegs(FWinputLuts,autogenLuts);

%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.fwBootCalcs(FWinputRegs,FWinputLuts,autogenRegs,autogenLuts);

end
