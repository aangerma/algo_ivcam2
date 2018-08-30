function [undistLut,dfzregs,eGeom,eProj] = trainAltDFZandProj(fw,darrTrain,darrVal)

[undistLut,dfzregs] = runDodCalib(fw,darrTrain);

[eGeom(1),eProj(1)] = evalDodResult(fw,darrTrain,undistLut,dfzregs);
[eGeom(2),eProj(2)] = evalDodResult(fw,darrVal,undistLut,dfzregs);


end
function [undistLut,dfzregs] = runDodCalib(fw,darr)
% Alternatingly optimize DFZ and undistort model.
% Optimize DFZ for better depth and undistort for better projection error.


end