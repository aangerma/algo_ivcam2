% Steps towards fov expander
%{
Method I:
1. Add to ang2xySF a fovx expander factor - either an [M,2] array with M
input angle bins and the relevant expansion factor, or a single value for
all angles. Do the same with xy2angSF.
2. Modify ang2xy bug fix.

Method II:
1. Let DFZ run wild
2. Iterate with undistort (on angx and angy - at the end transform to xy).
Method III:
1. Get Intrinsics from 1 spherical image. Find delay based on the depth.

Validate all methods by capturing 20 images from different angles. Train
with 15 and take the geometric and projection errors on the last 5. (Let
camera run for some time first).


%}
fw = ?
darr = captureImages( ? )
fovExpander = load('inOut117.mat'); fovExpander = fovExpander.inOut117;
[dfzRegs,undistRegs,undistlut,eGeom(1),eProj(1)] = trainWithFovModel(fw,darrTrain,darrVal,fovExpander);
[eGeom(2),eProj(2)] = trainAltDFZandProj(fw,darrTrain,darrVal);
[eGeom(3),eProj(3)] = trainIntrinsicsPlusDelay(fw,darrTrain,darrVal);