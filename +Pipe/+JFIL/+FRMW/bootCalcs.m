function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
%% pre calc
if ~regs.FRMW.preCalcBypass
    [preCalcsRegs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    regs = Firmware.mergeRegs(preCalcsRegs,regs);
end

end