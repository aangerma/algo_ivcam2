function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

%% pre calc
if(~regs.FRMW.preCalcBypass)
    [PreCalcsRegs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    PreCalcsluts = Firmware.mergeRegs(luts,autogenLuts);
else
    PreCalcsRegs=regs;
    PreCalcsluts=luts;
end
%% prepare for FW

[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(PreCalcsRegs,PreCalcsluts );
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);
FWinputLuts = Firmware.mergeRegs(FWinputLuts,autogenLuts);


%% Run fw bootcalcs
[regs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.fwBootCalcs(FWinputRegs,FWinputLuts,autogenRegs,autogenLuts);

end