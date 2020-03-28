function [xLosTrue, yLosTrue, xOutbound, yOutbound] = CalcTrueLos(regs, thermalTable, tpsUndistModel, xLos, yLos, ldd, vBiasMat)

    sz = size(xLos);
    
    % LOS to DSM
    if exist('vBiasMat', 'var')
        [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd, vBiasMat);
    else
        [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd);
    end
    params = struct('dsmXscale', dsmVals.xScale, 'dsmXoffset', dsmVals.xOffset, 'dsmYscale', dsmVals.yScale, 'dsmYoffset', dsmVals.yOffset);
    [dsmX, dsmY] = Calibration.aux.transform.applyDsm(vec(xLos), vec(yLos), params, 'direct');
    
    % DSM to  LOS
    [xLosTrue, yLosTrue, xOutbound, yOutbound] = CalcTrueLosFromDsm(regs, tpsUndistModel, reshape(dsmX, sz), reshape(dsmY, sz));
    
end