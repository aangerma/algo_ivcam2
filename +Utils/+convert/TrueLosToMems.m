function [xLos, yLos, xOutbound, yOutbound] = TrueLosToMems(regs, thermalTable, tpsUndistModel, xLosTrue, yLosTrue, ldd, vBiasMat)
    % TrueLosToMems
    %   Converts "true" (i.e. error-free) LOS report to true outbound ray direction and to MEMS angles, based on calibation results.
    
    sz = size(xLosTrue);
    
    % true LOS to DSM
    [dsmX, dsmY, xOutbound, yOutbound] = Utils.convert.TrueLosToDsm(regs, tpsUndistModel, xLosTrue, yLosTrue);
    
    % DSM to reported LOS
    if exist('vBiasMat', 'var')
        [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd, vBiasMat);
    else
        [dsmVals, ~] = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', thermalTable), regs, [0,94], ldd);
    end
    params = struct('dsmXscale', dsmVals.xScale, 'dsmXoffset', dsmVals.xOffset, 'dsmYscale', dsmVals.yScale, 'dsmYoffset', dsmVals.yOffset);
    [xLos, yLos] = Utils.convert.applyDsm(vec(dsmX), vec(dsmY), params, 'inverse');
    xLos = reshape(xLos, sz);
    yLos = reshape(yLos, sz);

end