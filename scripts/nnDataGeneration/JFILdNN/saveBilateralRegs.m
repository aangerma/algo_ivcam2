function [  ] = saveBilateralRegs( regs, file_name )
%SAVEBILATERALREGS saves the needed regs as a struct. 
% The file is mat file is loaded in tensorflow and used as an
% initialization for the neural net.

btRegs.biltConfThr = regs.JFIL.biltConfThr;
btRegs.rdSharpness = regs.JFIL.bilt3SharpnessR;
btRegs.sdSharpness = regs.JFIL.biltSharpnessS;
btRegs.rConfAdapt = 16;
btRegs.sConfAdapt = 16;
btRegs.depthAdaptR = regs.JFIL.biltDepthAdaptR;
btRegs.depthAdaptS = regs.JFIL.biltDepthAdaptS;
btRegs.gaussFilters = reshape(regs.JFIL.biltGauss, 6, 32);

save(file_name,'btRegs')
end

