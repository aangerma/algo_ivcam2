function [ oVec ] = applyFOVexOnOutVec( preExpVec, fovExpanderRef,regs )
% Applies distortion accounting for virtual mirror representation due to FOVex.
%   Input & output angles are all in degrees.
%   Note: linear scaling by the lens is actually assimilated in FOV estimation preceding this function.
% Recieves iVec, an Nx3 vector. A fovExpander Model.
% Applies the expantion factor to the angle between iVec and and the z-aix
% ([0,0,1]).
if isempty(fovExpanderRef)
    oVec = preExpVec;
    return;
end
assert(any(size(preExpVec)==3));
transposed = 0;
if size(preExpVec,1)==3
    transposed = 1;
    preExpVec = preExpVec';
end

range = sqrt(sum(preExpVec.^2,2));
preExpVec = preExpVec./range;


oVec = zeros(size(preExpVec));

fovExpInAngles = acosd(oVec(:,3)); % Entering angles to the fov expander
oAng = interp1(fovExpanderRef(:,1),fovExpanderRef(:,2),fovExpInAngles); % Out angles in degrees
oVec(:,3) = cosd(oAng);
oVec(:,1) = iVec(:,1).*sqrt((1-oVec(:,3).^2)./(iVec(:,1).^2+iVec(:,2).^2));
oVec(:,2) = iVec(:,2).*sqrt((1-oVec(:,3).^2)./(iVec(:,1).^2+iVec(:,2).^2));

% apply undistort on the output vec
oVec = applyPostFovExUndistModel(oVec,regs);


oVec = oVec.*range;

if transposed
    oVec = oVec';
end
oVec(isnan(oVec)) = 0;
end
%{
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
%}
function oAng = outAngleForZ(zVec,fovExpander)
% For each z - calculate the angle. Look in the lookup table for the right
% angle and use linear interpolation.

end
function undistVec = applyPostFovExUndistModel(postExpVec,regs)
    xIn = postExpVec(:,1)./postExpVec(:,3); % tanX
    yIn = postExpVec(:,2)./postExpVec(:,3); % tanY
    
    
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
    
    oVec = [xOut,yOut,ones(size(xOut))];
    undistVec = normr(oVec);
    
    
end
