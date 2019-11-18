function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts,regMeta)
%% pre calc
if(~regs.FRMW.preCalcBypass)
    [PreCalcsRegs,autogenRegs,autogenLuts] = Pipe.INFC.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    PreCalcsluts = Firmware.mergeRegs(luts,autogenLuts);
else
    PreCalcsRegs=regs;
    PreCalcsluts=luts;
end
%% prepare for FW
[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(PreCalcsRegs,PreCalcsluts,regMeta);
FWinputRegs = Firmware.mergeRegs(FWinputRegs,autogenRegs);

%% Run fw bootcalcs
[regs,autogenRegs] = Pipe.INFC.FRMW.fwBootCalcs(FWinputRegs,autogenRegs);

end

