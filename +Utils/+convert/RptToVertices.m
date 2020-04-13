function vertices = RptToVertices(rpt, regs, tpsUndistModel)
    % RptToVertices
    %   Converts Nx3 RPT structure ([raw RTD, dsm X, dsm Y]) to 3D vertices in Cartesian coordinates.
    
    % direction calculation
    [angx, angy] = Calibration.Undist.applyPolyUndistAndPitchFix(rpt(:,2), rpt(:,3), regs);
    vUnit = Calibration.aux.ang2vec(angx, angy, regs)';
    vUnit = Calibration.Undist.undistByTPSModel(vUnit, tpsUndistModel);
    
    % RTD correction
    tanY = vUnit(:,2)./vUnit(:,3);
    angxNorm = abs(rpt(:,2) - regs.FRMW.rtdOverX(6))/2047;
    rtd = rpt(:,1) - regs.DEST.txFRQpd(1);
    rtd = rtd + (tanY.^[2,4,6]) * regs.FRMW.rtdOverY';
    rtd = rtd + (angxNorm.^(2:6)) * regs.FRMW.rtdOverX(1:5)';
    
    % conversion to vertices
    if regs.DEST.hbaseline
        sing = vUnit(:,1);
    else
        sing = vUnit(:,2);
    end
    r = (0.5*(rtd.^2 - regs.DEST.baseline2))./(rtd - regs.DEST.baseline.*sing);
    vertices = double(vUnit.*r);
    
end