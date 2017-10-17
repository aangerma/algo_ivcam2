function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

[regs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.RAST.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.DCOR.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.PCKR.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.STAT.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts);

end

