function tpsUndistModel = calcTPSModel(d,croppedVertices,allVertices,runParams,isXY0isR1)
    if~exist('isXY0isR1','var')
        isXY0isR1 = 0;
    end
    tanXYMeasured = cell(1,length(croppedVertices));
    tanXYFitted = cell(1,length(croppedVertices));
    for k = 1:length(croppedVertices)
        % Get rid off NaNs
        vNoNansCropped = croppedVertices{1,k};
        noNanVertices = ~isnan(vNoNansCropped(:,1));
        vNoNansCropped = vNoNansCropped(noNanVertices,:);
        vRef = d(k).pts3d;
        vRef = vRef(noNanVertices,:);
        % Calculate rotation and shift of rigid fit for cropped points,rotmat,
        [~,~,rotmat,shiftVec, meanVal] = Calibration.aux.rigidFit(vNoNansCropped,vRef);
        [tanXYMeasured{k},tanXYFitted{k}] = Calibration.DFZ.createPtsForPtsModel(allVertices{1,k},d(k).pts3d,meanVal,rotmat,shiftVec,d(k).grid(1:2));

    end
    tanXYMeasured = cell2mat(tanXYMeasured);
    tanXYFitted = cell2mat(tanXYFitted);

    tpsUndistModel= Calibration.Undist.createTpsUndistModel(tanXYMeasured,tanXYFitted,runParams);

end
