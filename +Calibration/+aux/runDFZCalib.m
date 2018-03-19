function [outregs,geomErr] = runDFZCalib(hw,darr,verbose)
%RUNDFZCALIB receives:
% hw interface, darr - array of captures d.
% This function set up the regs for best DFZ calibration and calls calibDFZ.
fw = hw.getFirmeware();
[regs,~] = fw.get();
%{
Set up:
1. spherical mode (a bit more accurate)
2. depthAsrange
3. invConfThreshold 
%}

hw.setReg('JFILinvBypass',true);
hw.setReg('DIGGsphericalEn',true);
hw.setReg('DESTdepthAsRange',true);
hw.shadowUpdate();

[outregs,geomErr,~]=calibDFZ(darr,regs,verbose);

% Return to origin
hw.setReg('JFILinvBypass',regs.JFIL.invBypass);
hw.setReg('DIGGsphericalEn',regs.DIGG.sphericalEn);
hw.setReg('DESTdepthAsRange',regs.DEST.depthAsRange);
hw.shadowUpdate();


end

