function vertices = ConvertLosToNormVertices(regs, dsmRegs, los)
    
    % Applying DSM (taken from Utils.convert.applyDsm)
    dsmX = (los(:,1) + dsmRegs.dsmXoffset) * dsmRegs.dsmXscale - 2047; % Nx1
    dsmY = (los(:,2) + dsmRegs.dsmYoffset) * dsmRegs.dsmYscale - 2047;
    
    % Applying DSM correction (taken from Calibration.Undist.applyPolyUndistAndPitchFix, fine vertical correction is excluded)
    dsmXcorrCoarse = dsmX + (dsmX/2047).^[1,2,3]*(vec(regs.FRMW.polyVars));
    dsmYcorrCoarse = dsmY + (dsmX/2047)*regs.FRMW.pitchFixFactor;
    dsmXcorr = dsmXcorrCoarse + (dsmXcorrCoarse/2047).^[1,2,3,4]*vec(regs.FRMW.undistAngHorz); % Nx1
    dsmYcorr = dsmYcorrCoarse;
    
    % Transforming to pre-FOVex directions (taken from Calibration.aux.ang2vec, shear is excluded)
    mode = regs.FRMW.mirrorMovmentMode;
    angX = dsmXcorr*(regs.FRMW.xfov(mode)*0.25/2047);
    angY = dsmYcorr*(regs.FRMW.yfov(mode)*0.25/2047);
    angles2xyz = @(x,y) [cosd(y).*sind(x), sind(y), cosd(y).*cosd(x)];
    laserIncidentDirection = angles2xyz(regs.FRMW.laserangleH, regs.FRMW.laserangleV+180);
    mirrorNormalDirection = angles2xyz(angX, angY);
    fovexIndicentDirection = laserIncidentDirection - 2*(mirrorNormalDirection*laserIncidentDirection').*mirrorNormalDirection; % Nx3
    fovexIndicentDirection = fovexIndicentDirection./sqrt(sum(fovexIndicentDirection.^2,2)); % normalizing to ensure unit direction vectors
    
    % Applying FOVex (taken from Calibration.aux.applyFOVex, distortion is excluded)
    if ~regs.FRMW.fovexExistenceFlag % unit without FOVex
        outboundDirection = fovexIndicentDirection;
    else
        outboundDirection = zeros(size(fovexIndicentDirection)); % Nx3
        angPreExp = acosd(fovexIndicentDirection(:,3)); % angle w.r.t. Z-axis [deg]
        angPostExp = angPreExp + angPreExp.^[1,2,3,4]*vec(regs.FRMW.fovexNominal);
        outboundDirection(:,3) = cosd(angPostExp);
        xyNorm = fovexIndicentDirection(:,1).^2+fovexIndicentDirection(:,2).^2; % can never be 0 in IVCAM2
        xyFactor = sqrt((1-outboundDirection(:,3).^2)./xyNorm);
        outboundDirection(:,1:2) = fovexIndicentDirection(:,1:2).*xyFactor;
    end
    
    % Transforming to normalized vertices
    vertices = outboundDirection./outboundDirection(:,3); % Nx3
    
end