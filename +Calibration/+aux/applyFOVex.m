function [ angx, angy ] = applyFOVex( angxPreExp, angyPreExp, regs )
% Applies distortion accounting for virtual mirror representation due to FOVex.
%   Input & output angles are all in degrees.
%   Note: linear scaling by the lens is actually assimilated in FOV estimation preceding this function.

assert(size(angxPreExp,2)==1 && size(angxPreExp,2)==1, 'applyFOVex expects inputs to be column vectors')
if regs.FRMW.fovexDistModel % FOVex distortion model applies for the pixels domain
    xIn = tand(angxPreExp);
    yIn = tand(angyPreExp);
else % FOVex distortion model applies for the angles domain
    xIn = angxPreExp;
    yIn = angyPreExp;
end

% Auxiliary calculations
xCentered = xIn - regs.FRMW.fovexCenter(1);
yCentered = yIn - regs.FRMW.fovexCenter(2);
r2 = xCentered.^2 + yCentered.^2;

% Applying lens distortion
radialDist = [r2, r2.^2, r2.^3]*regs.FRMW.fovexRadialK';
tangentialDistX = regs.FRMW.fovexTangentP(1)*(r2+2*xCentered.^2) + 2*regs.FRMW.fovexTangentP(2)*xCentered.*yCentered;
tangentialDistY = regs.FRMW.fovexTangentP(2)*(r2+2*yCentered.^2) + 2*regs.FRMW.fovexTangentP(1)*xCentered.*yCentered;
xOut = xIn + xCentered.*radialDist + tangentialDistX;
yOut = yIn + yCentered.*radialDist + tangentialDistY;

if regs.FRMW.fovexDistModel
    angx = atand(xOut);
    angy = atand(yOut);
else
    angx = xOut;
    angy = yOut;
end