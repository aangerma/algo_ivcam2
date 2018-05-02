function regs = setThermalRegs(params)
    
    regs.DCOR.spare=zeros(8,1,'single');
    regs.DCOR.spare(1)=params.thermal.tslope;
    regs.DCOR.spare(2)=params.thermal.tslope*prams.thermal.t0;

end