function [ results ] = validateFOV( hw,regs,FE )
%VALIDATEFOV returns a struct that details the fov of the mirror
%and that of the laser (smaller than that of the mirror). In addition, it
%calculates the min and max angles of projection when scanning up and
%scanning down.
if ~exist('FE','var')
   FE = []; 
end

r = Calibration.RegState(hw);
r.add('DIGGsphericalEn'    ,true     );
r.set();
hw.cmd('iwb e2 06 01 00'); % Remove bias
Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'Please Make Sure Borders Are Bright');
[imU,imD]=Calibration.dataDelay.getScanDirImgs(hw);
r.reset();
hw.cmd('iwb e2 06 01 70'); % Return bias

results = Calibration.validation.calculateFOV(imU,imD,regs,FE);
end