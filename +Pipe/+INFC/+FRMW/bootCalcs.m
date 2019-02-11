function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
%% Run fw bootcalcs
[regs,autogenRegs] = Pipe.INFC.FRMW.fwBootCalcs(regs,autogenRegs);

end

