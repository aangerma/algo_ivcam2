function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
    %{

    %% pre calc
    [PreCalcsRegs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    PreCalcsluts = Firmware.mergeRegs(luts,autogenLuts);
    %}


    %% write to EPROM

    %[FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(PreCalcsRegs,PreCalcsluts );
    [FWinputRegs,FWinputLuts] = Pipe.getRegsForfwBootCalcs(regs,luts );
    regs = Firmware.mergeRegs(regs,FWinputRegs);
    luts = Firmware.mergeRegs(luts,FWinputLuts);

    %% Run fw bootcalcs
    [regs,autogenRegs,autogenLuts]      = Pipe.RAST.FRMW.fwBootCalcs(regs,luts,autogenRegs,autogenLuts);
end
