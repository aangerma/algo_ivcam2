function [dsmX, dsmY, xOutbound, yOutbound] = TrueLosToDsm(regs, tpsUndistModel, xLosTrue, yLosTrue)
    % TrueLosToDsm
    %   Converts "true" (i.e. error-free) LOS report to true outbound ray direction and DSM angles, based on calibation results.

    sz = size(xLosTrue);
    angles2xyz = @(angx,angy) [cosd(angy).*sind(angx), sind(angy), cosd(angy).*cosd(angx)];
    
    % LOS to mirror direction
    vUnit = angles2xyz(vec(xLosTrue)/2, vec(yLosTrue)/2);
    
    % mirror direction to actual projection direction
    laserIncidentDirection = angles2xyz(regs.FRMW.laserangleH, regs.FRMW.laserangleV+180);
    vUnit = laserIncidentDirection-2*(vUnit*laserIncidentDirection').*vUnit;
    vUnit = Calibration.aux.applyFOVex(vUnit, regs);
    xOutbound = atand(vUnit(:,1)./vUnit(:,3));
    yOutbound = asind(vUnit(:,2));
    xOutbound = reshape(xOutbound, sz);
    yOutbound = reshape(yOutbound, sz);
    
    % projection direction to DSM
    vUnit = Calibration.Undist.inverseUndistByTPSModel(vUnit, tpsUndistModel);
    [angx, angy] = Calibration.aux.vec2ang(vUnit, regs);
    [dsmX, dsmY] = Calibration.Undist.inversePolyUndistAndPitchFix(angx, angy, regs);
    dsmX = reshape(dsmX, sz);
    dsmY = reshape(dsmY, sz);
    
end