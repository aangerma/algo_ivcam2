function [xLosTrue, yLosTrue, xOutbound, yOutbound] = DsmToTrueLos(regs, tpsUndistModel, dsmX, dsmY)
    % DsmToTrueLos
    %   Converts DSM angles to true outbound ray direction and to "true" (i.e. error-free) LOS report, based on calibation results.
    
    sz = size(dsmX);
    angles2xyz = @(angx,angy) [cosd(angy).*sind(angx), sind(angy), cosd(angy).*cosd(angx)];
    
    % DSM to actual projection direction
    [angx, angy] = Calibration.Undist.applyPolyUndistAndPitchFix(vec(dsmX), vec(dsmY), regs);
    vUnit = Calibration.aux.ang2vec(angx, angy, regs)';
    vUnit = Calibration.Undist.undistByTPSModel(vUnit, tpsUndistModel);
    xOutbound = atand(vUnit(:,1)./vUnit(:,3));
    yOutbound = asind(vUnit(:,2));
    xOutbound = reshape(xOutbound, sz);
    yOutbound = reshape(yOutbound, sz);
    
    % projection direction to mirror direction
    vUnit = Calibration.aux.applyFOVexInv(vUnit, regs);
    laserIncidentDirection = angles2xyz(regs.FRMW.laserangleH, regs.FRMW.laserangleV+180);
    vUnit = normr(vUnit - repmat(laserIncidentDirection, size(vUnit,1), 1));

    % mirror direction to LOS
    xLosTrue = atand(vUnit(:,1)./vUnit(:,3))*2;
    yLosTrue = asind(vUnit(:,2))*2;
    xLosTrue = reshape(xLosTrue, sz);
    yLosTrue = reshape(yLosTrue, sz);
    
end