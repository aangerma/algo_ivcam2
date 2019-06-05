function outVec = applyFOVex( inVec, regs )
% Applies distortion accounting for virtual mirror representation due to FOVex.

if ~regs.FRMW.fovexExistenceFlag % unit without FOVex
    outVec = inVec;
    return
end

% Preparations
assert(any(size(inVec)==3));
transposed = 0;
if (size(inVec,1)==3) % applyFOVex processes row vectors
    transposed = 1;
    inVec = inVec';
end
range = sqrt(sum(inVec.^2,2));
inVec = inVec./range; % normalizing to ensure unit direction vectors
nominalOutVec = zeros(size(inVec));

% Applying FOV expansion
angPreExp = acosd(inVec(:,3)); % angle w.r.t. Z-axis [deg]
angPostExp = angPreExp + angPreExp.^[1,2,3,4]*vec(regs.FRMW.fovexNominal);
nominalOutVec(:,3) = cosd(angPostExp);
xyFactor = sqrt((1-nominalOutVec(:,3).^2)./(inVec(:,1).^2+inVec(:,2).^2));
nominalOutVec(:,1:2) = inVec(:,1:2).*xyFactor;

% Converting to image plane
uv = nominalOutVec(:,1:2)./nominalOutVec(:,3);
uvCentered = uv-regs.FRMW.fovexCenter;
r2 = sum(uvCentered.^2,2);

% Applying lens distortion
if regs.FRMW.fovexLensDistFlag
    radialDist = (r2.^[1,2,3])*regs.FRMW.fovexRadialK';
    tangentialDist = regs.FRMW.fovexTangentP.*(r2+2*uvCentered.^2) + 2*fliplr(regs.FRMW.fovexTangentP).*prod(uvCentered,2);
    uvDistorted = uv + uvCentered.*radialDist + tangentialDist;
else
    uvDistorted = uv;
end

% Back-conversion to 3D
uvFactor = 1./sqrt(1+sum(uvDistorted.^2,2));
outVec = [uvDistorted.*uvFactor, uvFactor];

% Aligning with original representation
outVec = outVec.*range;
if transposed
    outVec = outVec';
end
outVec(isnan(outVec)) = 0;
