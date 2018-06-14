function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

[regs,autogenRegs] = generalRegisters(regs,autogenRegs);
[regs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.RAST.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.DCOR.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.PCKR.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.STAT.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);

end

function [regs,autogenRegs] = generalRegisters(regs,autogenRegs)
autogenRegs.GNRL.tmplLength = uint16(double(regs.GNRL.codeLength)*double(regs.GNRL.sampleRate));
autogenRegs.GNRL.zNorm = single(bitshift(1,regs.GNRL.zMaxSubMMExp));
autogenRegs.EXTL.auxPItxCode=regs.FRMW.txCode;
autogenRegs.EXTL.auxPItxCodeLength=uint32(regs.GNRL.codeLength);
regs = FirmwareBase.mergeRegs(regs,autogenRegs);
end

