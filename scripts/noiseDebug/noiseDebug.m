% Set spherical enable and jfil bypass and collect the CMA
hw = HWinterface();
hw.getFrame(30);
hw.setReg('DIGGsphericalEn'    ,true); 
[cma,cmaSTD] = readCMA(hw);
save 'cma_code_52_projector_covered.mat' 'cma'
plot(squeeze(cma(200,300,:)))
