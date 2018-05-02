function regs = setThermalRegs(params)
    
    regs.DCOR.spare=zeros(8,1,'single');
    regs.DCOR.spare(1)=params.tslope;
    regs.DCOR.spare(2)=params.tslope*params.t0;

end