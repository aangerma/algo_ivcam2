function los = ConvertNormVerticesToLos(regs, dsmRegs, vertices)
   
    % Transforming to direction vector
    outboundDirection = vertices./sqrt(sum(vertices.^2,2)); % Nx3
    
    % Reverting FOVex (based on Calibration.aux.applyFOVex, distortion is excluded)
    if ~regs.FRMW.fovexExistenceFlag % unit without FOVex
        fovexIndicentDirection = outboundDirection;
    else
        fovexIndicentDirection = zeros(size(outboundDirection)); % Nx3
        angPostExp = acosd(outboundDirection(:,3)); % angle w.r.t. Z-axis [deg]
        angGrid = (0:45)';
        angOutOnGrid = angGrid + angGrid.^[1,2,3,4]*vec(regs.FRMW.fovexNominal);
        angPreExp = interp1(angOutOnGrid, angGrid, angPostExp);
        fovexIndicentDirection(:,3) = cosd(angPreExp);
        xyNorm = outboundDirection(:,1).^2+outboundDirection(:,2).^2; % can never be 0 in IVCAM2
        xyFactor = sqrt((1-fovexIndicentDirection(:,3).^2)./xyNorm);
        fovexIndicentDirection(:,1:2) = outboundDirection(:,1:2).*xyFactor;
    end
    
    % Transforming to corrected DSM values (taken from Calibration.aux.vec2ang, shear is excluded)
    angles2xyz = @(x,y) [cosd(y).*sind(x), sind(y), cosd(y).*cosd(x)];
    laserIncidentDirection = angles2xyz(regs.FRMW.laserangleH, regs.FRMW.laserangleV+180);
    mirrorNormalDirection = fovexIndicentDirection - laserIncidentDirection;
    mirrorNormalDirection = mirrorNormalDirection./sqrt(sum(mirrorNormalDirection.^2,2)); % Nx3
    angX = atand(mirrorNormalDirection(:,1)./mirrorNormalDirection(:,3));
    angY = asind(mirrorNormalDirection(:,2));
    mode = regs.FRMW.mirrorMovmentMode;
    dsmXcorr = single(angX)/(regs.FRMW.xfov(mode)*0.25/2047); % Nx1
    dsmYcorr = single(angY)/(regs.FRMW.yfov(mode)*0.25/2047);
    
    % Reverting DSM correction (based on Calibration.Undist.applyPolyUndistAndPitchFix, fine vertical correction is excluded)
    dsmGrid = (-2100:10:2100)';
    dsmXcoarseOnGrid = dsmGrid + (dsmGrid/2047).^[1,2,3]*vec(regs.FRMW.polyVars);
    dsmXcorrOnGrid = dsmXcoarseOnGrid + (dsmXcoarseOnGrid/2047).^[1,2,3,4]*vec(regs.FRMW.undistAngHorz);
    dsmX = interp1(dsmXcorrOnGrid, dsmGrid, dsmXcorr); % Nx1
    dsmY = dsmYcorr - (dsmX/2047)*regs.FRMW.pitchFixFactor;

    % Reverting DSM (taken from Utils.convert.applyDsm)
    losX = (dsmX + 2047)/double(dsmRegs.dsmXscale) - double(dsmRegs.dsmXoffset);
    losY = (dsmY + 2047)/double(dsmRegs.dsmYscale) - double(dsmRegs.dsmYoffset);
    los = [losX, losY];
    
end