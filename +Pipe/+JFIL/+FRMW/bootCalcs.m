function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts,regMeta)
%% pre calc
if ~regs.FRMW.preCalcBypass
    [preCalcsRegs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.preCalcs(regs,luts,autogenRegs,autogenLuts);
    regs = Firmware.mergeRegs(regs,preCalcsRegs);
else 
    % copy to autogen regs from precalc
    if(~exist('regMeta','var'))
        f=Firmware();
        m=f.getMeta(); 
    else
        m = regMeta;
    end
    Autojfilregs=m(strcmp('JFIL',{m.algoBlock}) & [m.autogen]==-1); 
    algoNames=unique({Autojfilregs.algoName});
    for i=1:length(algoNames)
        autogenRegs.JFIL.(algoNames{i})=regs.JFIL.(algoNames{i}); 
    end 
end

end