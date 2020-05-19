function data = PreProcessing(regs, acData, dsmRegs, origK, isValidPix, maxScalingStep)
    
    % input storage
    data.regs = regs;
    data.dsmRegs = dsmRegs;
    data.origK = origK;
    data.maxScalingStep = maxScalingStep;
    [data.lastLosScaling, data.lastLosShift] = OnlineCalibration.K2DSM.ConvertAcDataToLosError(data.dsmRegs, acData); % for focusing the search
    
    % backward model: transforming pixels to original LOS, as it was during factory calibration
    sz = size(isValidPix);
    [yPixGrid, xPixGrid] = ndgrid(0:sz(1)-1, 0:sz(2)-1);
    data.verticesOrig = [xPixGrid(isValidPix), yPixGrid(isValidPix), ones(sum(isValidPix(:)),1)] * inv(origK)';
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse'); % existing DSM correction must be reverted
    data.losOrig = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegsOrig, data.verticesOrig);
    
    % forward model: shift ratios calculation, using current camera state
    losShift = 1;
    
    shiftedLosX = data.losOrig(:,1) + losShift; % horizontal shift
    shiftedVertices = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, data.dsmRegs, [shiftedLosX, data.losOrig(:,2)]);
    shiftRatio = [origK(1,1), origK(2,2), 1].*(shiftedVertices-data.verticesOrig) / losShift;
    LxxLyx = mean(shiftRatio,1);
    
    shiftedLosY = data.losOrig(:,2) + losShift; % vertical shift
    shiftedVertices = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, data.dsmRegs, [data.losOrig(:,1), shiftedLosY]);
    shiftRatio = [origK(1,1), origK(2,2), 1].*(shiftedVertices-data.verticesOrig) / losShift;
    LxyLyy = mean(shiftRatio,1);
    
    data.shiftRatioMat = double([LxxLyx(1), LxyLyy(1); LxxLyx(2), LxyLyy(2)]);
end


