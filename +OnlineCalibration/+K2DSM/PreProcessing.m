function data = PreProcessing(regs, acData, dsmRegs, origK, isValidPix, maxScalingStep)
    
    % input storage
    data.regs = regs;
    data.dsmRegs = dsmRegs;
    data.origK = origK;
    data.maxScalingStep = maxScalingStep;
    [data.lastLosScaling, ~] = OnlineCalibration.K2DSM.ConvertAcDataToLosError(data.dsmRegs, acData); % for focusing the search
    
    % backward model: transforming pixels to original LOS, as it was during factory calibration
    sz = size(isValidPix);
    [yPixGrid, xPixGrid] = ndgrid(0:sz(1)-1, 0:sz(2)-1);
    data.verticesOrig = [xPixGrid(isValidPix), yPixGrid(isValidPix), ones(sum(isValidPix(:)),1)] * inv(origK)';
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse'); % existing DSM correction must be reverted
    data.losOrig = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegsOrig, data.verticesOrig);
    
end


