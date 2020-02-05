function [ptsWithZ, gridSize] = getCornersDataFromThermalFrame(frame, regs, calibParams, isSphericalMode)
    % preparations
    sz = size(frame.i);
    pixelCropWidth = sz.*calibParams.gnrl.cropFactors;
    frame.i([1:pixelCropWidth(1),round(sz(1)-pixelCropWidth(1)):sz(1)],:) = 0;
    frame.i(:,[1:pixelCropWidth(2),round(sz(2)-pixelCropWidth(2)):sz(2)]) = 0;
    % checkerboard detection
    if isempty(calibParams.gnrl.cbGridSz)
        CB = CBTools.Checkerboard (frame.i, 'targetType', 'checkerboard_Iv2A1','imageRotatedBy180',true,'nonRectangleFlag',logical(calibParams.gnrl.nonRectangleFlag));
        gridSize = CB.getGridSize;
        pts = CB.getGridPointsList;
        colors = CB.getColorMap;
        if isfield(frame,'yuy2')
             CB = CBTools.Checkerboard (frame.yuy2, 'targetType', 'checkerboard_Iv2A1','nonRectangleFlag',logical(calibParams.gnrl.nonRectangleFlag));
             ptsColor = CB.getGridPointsMat;
        end
    else
        colors = [];
        CB = CBTools.Checkerboard (frame.i,'expectedGridSize',calibParams.gnrl.cbGridSz);
        pts = CB.getGridPointsList;
        gridSize = CB.getGridSize;
        if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
            warning('Checkerboard not detected in IR image. Entire target must be included in the frame.');
            ptsWithZ = [];
            return;
        end
        if isfield(frame,'yuy2')
            CB = CBTools.Checkerboard (frame.yuy2,'expectedGridSize',calibParams.gnrl.cbGridSz);
            ptsColor = CB.getGridPointsList;
            gridSizeRgb = CB.getGridSize;
            if ~isequal(gridSizeRgb, calibParams.gnrl.cbGridSz)
                warning('Checkerboard not detected in color image. Entire target must be included in the frame.');
                ptsWithZ = [];
                return;
            end
        end
    end
    % corners extraction
    if isSphericalMode
        assert(regs.DIGG.sphericalEn==1, 'Frames for ATC must be captured in spherical mode')
        if isempty(colors)
            rpt = Calibration.aux.samplePointsRtd(frame.z,pts,regs);
        else
            rpt = Calibration.aux.samplePointsRtd(frame.z,reshape(pts,20,28,2),regs,0,colors,calibParams.gnrl.sampleRTDFromWhiteCheckers);
        end
        rpt(:,1) = rpt(:,1) - regs.DEST.txFRQpd(1);
        ptsWithZ = [rpt,reshape(pts,[],2)]; % without XYZ which is not calibrated well at this stage
        ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
        if isfield(frame,'yuy2')
            ptsWithZ = [ptsWithZ,reshape(ptsColor,[],2)];
        end
    else
        zIm = single(frame.z)/single(regs.GNRL.zNorm);
        if calibParams.gnrl.sampleRTDFromWhiteCheckers && isempty(calibParams.gnrl.cbGridSz)
            [zPts,~,~,pts,~] = CBTools.valuesFromWhitesNonSq(zIm,reshape(pts,20,28,2),colors,1/8);
            pts = reshape(pts,[],2);
        else
            zPts = interp2(zIm,pts(:,1),pts(:,2));
        end
        matKi = (regs.FRMW.kRaw)^-1;
        u = pts(:,1)-1;
        v = pts(:,2)-1;
        tt = zPts'.*[u';v';ones(1,numel(v))];
        verts = (matKi*tt)';
        % generate ptzWithZ
        if regs.DEST.hbaseline
            rxLocation = [regs.DEST.baseline,0,0];
        else
            rxLocation = [0,regs.DEST.baseline,0];
        end
        rtd = sqrt(sum(verts.^2,2)) + sqrt(sum((verts - rxLocation).^2,2));
        angx = rtd*0;% All nan will cause the analysis to fail
        angy = rtd*0;% All nan will cause the analysis to fail
        ptsWithZ = [rtd,angx,angy,pts,verts];
        ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
        if isfield(frame,'yuy2')
            ptsWithZ = [ptsWithZ,reshape(ptsColor,[],2)];
        end
    end
end
