function [xLosTrue, yLosTrue, xOutbound, yOutbound] = MemsToTrueLos(regs, thermalTable, tpsUndistModel, xLos, yLos, ldd, vBiasMat)
    % MemsToTrueLos
    %   Converts MEMS angles to true outbound ray direction and to "true" (i.e. error-free) LOS report, based on calibation results.
    
    sz = size(xLos);
    
    % reported LOS to DSM
    if exist('vBiasMat', 'var')
        [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd, vBiasMat);
    else
        [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd);
    end
    params = struct('dsmXscale', dsmVals.xScale, 'dsmXoffset', dsmVals.xOffset, 'dsmYscale', dsmVals.yScale, 'dsmYoffset', dsmVals.yOffset);
    [dsmX, dsmY] = Utils.convert.applyDsm(vec(xLos), vec(yLos), params, 'direct');
    
    % DSM to true LOS
    [xLosTrue, yLosTrue, xOutbound, yOutbound] = Utils.convert.DsmToTrueLos(regs, tpsUndistModel, reshape(dsmX, sz), reshape(dsmY, sz));
    
end