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
     data.verticesOrig = [sampleByMask(xPixGrid,isValidPix), sampleByMask(yPixGrid,isValidPix), ones(sum(isValidPix(:)),1)] * inv(origK)';
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse'); % existing DSM correction must be reverted
    data.losOrig = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegsOrig, data.verticesOrig);
    
end


function [values] = sampleByMask(I,binMask)
    % Extract values from image I using the binMask with the order being
    % row and then column
    I = I';
    values = I(binMask');
end
