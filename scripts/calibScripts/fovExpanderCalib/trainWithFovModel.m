function [dfzRegs,undistRegs,undistlut,eGeom,eProj] = trainWithFovModel(fw,darrTrain,darrVal,FE)
regs = fw.get();

[dfzRegs,eGeom(1),eProj(1)] = calibDFZWithFE(darrTrain,regs,0,FE);
[~,eGeom(2),eProj(2)] = calibDFZWithFE(darrVal,regs,1,FE);

fw.setRegs(dfzRegs,'');
% [undistLUT] - calculate it.
[undistlut.FRMW.undistModel,undistRegs,~] = calibUndistAng2xyBugFixWithFE(fw,FE);
end

