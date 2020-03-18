function [xLosTrue, yLosTrue] = CalcTrueLos(regs, thermalTable, tpsUndistModel, xLos, yLos, ldd)

    sz = size(xLos);
    angles2xyz = @(angx,angy) [cosd(angy).*sind(angx), sind(angy), cosd(angy).*cosd(angx)];
    
    % LOS to DSM
    [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd);
    params = struct('dsmXscale', dsmVals.xScale, 'dsmXoffset', dsmVals.xOffset, 'dsmYscale', dsmVals.yScale, 'dsmYoffset', dsmVals.yOffset);
    [dsmX, dsmY] = Calibration.aux.transform.applyDsm(vec(xLos), vec(yLos), params, 'direct');
    
    % DSM to undist projection direction
    [angx, angy] = Calibration.Undist.applyPolyUndistAndPitchFix(dsmX, dsmY, regs);
    vUnit = Calibration.aux.ang2vec(angx, angy, regs)';
    vUnit = Calibration.Undist.undistByTPSModel(vUnit, tpsUndistModel);
    
    % projection direction to mirror direction
    vUnit = Calibration.aux.applyFOVexInv(vUnit, regs);
    laserIncidentDirection = angles2xyz(regs.FRMW.laserangleH, regs.FRMW.laserangleV+180);
    vUnit = normr(vUnit - repmat(laserIncidentDirection, size(vUnit,1), 1));

    % mirror direction to LOS
    xLosTrue = atand(vUnit(:,1)./vUnit(:,3))*2;
    yLosTrue = asind(vUnit(:,2))*2;
    xLosTrue = reshape(xLosTrue, sz(1), sz(2));
    yLosTrue = reshape(yLosTrue, sz(2), sz(2));
    
end