function out = RptToVertices(in, regs, tpsUndistModel, mode)
    % RptToVertices
    %   Converts Nx3 RPT structure ([raw RTD, dsm X, dsm Y]) to 3D vertices in Cartesian coordinates, and vice versa.
    
    if strcmp(mode, 'direct') % RPT to vertices (in = rpt, out = vertices)
        % direction calculation
        [angx, angy] = Calibration.Undist.applyPolyUndistAndPitchFix(in(:,2), in(:,3), regs);
        vUnit = Calibration.aux.ang2vec(angx, angy, regs)';
        vUnit = Calibration.Undist.undistByTPSModel(vUnit, tpsUndistModel);
        
        % RTD correction
        tanY = vUnit(:,2)./vUnit(:,3);
        angxNorm = abs(in(:,2) - regs.FRMW.rtdOverX(6))/2047;
        rtd = in(:,1) - regs.DEST.txFRQpd(1);
        rtd = rtd + (tanY.^[2,4,6]) * regs.FRMW.rtdOverY';
        rtd = rtd + (angxNorm.^(2:6)) * regs.FRMW.rtdOverX(1:5)';
        
        % conversion to vertices
        if regs.DEST.hbaseline
            sing = vUnit(:,1);
        else
            sing = vUnit(:,2);
        end
        r = (0.5*(rtd.^2 - regs.DEST.baseline2))./(rtd - regs.DEST.baseline.*sing);
        out = double(vUnit.*r);
        
    elseif strcmp(mode, 'inverse') % vertices to RPT (in = vertices, out = rpt)
        % breaking down to direction and RTD
        calcDist = @(v) sqrt(sum(v.^2,2));
        rxPos = [0; regs.DEST.baseline; 0]';
        r = calcDist(in);
        vUnit = in./r;
        rtd = r + calcDist(in - rxPos);
        
        % DSM calculation
        vUnitPreTps = Calibration.Undist.inverseUndistByTPSModel(vUnit, tpsUndistModel);
        [angx, angy] = Calibration.aux.vec2ang(vUnitPreTps, regs);
        [angxPreUndist, angyPreUndist] = Calibration.Undist.inversePolyUndistAndPitchFix(angx, angy, regs);

        % RTD reconstruction
        angxNorm = abs(angxPreUndist - regs.FRMW.rtdOverX(6))/2047;
        tanY = vUnit(:,2)./vUnit(:,3);
        rtd = rtd - (angxNorm.^(2:6)) * regs.FRMW.rtdOverX(1:5)';
        rtd = rtd - (tanY.^[2,4,6]) * regs.FRMW.rtdOverY';
        rtd = rtd + regs.DEST.txFRQpd(1);
        
        out = [rtd(:), angxPreUndist(:), angyPreUndist(:)];
        
    else
        error('Illegal mode: mode can be either ''direct'' or ''inverse''.')
        
    end
end