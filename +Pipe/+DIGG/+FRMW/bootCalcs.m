function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts, getMeta)

%% pre calc
if(~regs.FRMW.preCalcBypass)
    [PreCalcsRegs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    PreCalcsluts = Firmware.mergeRegs(luts,autogenLuts);
else
    PreCalcsRegs=regs;
    PreCalcsluts=luts;
end
%% prepare for FW

[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(PreCalcsRegs,PreCalcsluts,getMeta);
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);
FWinputLuts = Firmware.mergeRegs(FWinputLuts,autogenLuts);


%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.fwBootCalcs(FWinputRegs,FWinputLuts,autogenRegs,autogenLuts);

end