function [dsmVals, rtdVals] = calcAlgoThermalDsmRtd(algoThermalCalibData, regs, tableLddRange, lddVec, vBiasMat)

isTableWithDsm = (size(algoThermalCalibData.table,2)==5);
nBins = size(algoThermalCalibData.table,1);
if (size(lddVec,1) > 1)
    lddVec = lddVec';
end

if isTableWithDsm
    if ~exist('vBiasMat', 'var')
        tableLddGrid = linspace(tableLddRange(1), tableLddRange(2), nBins);
        vBiasMat(1,:) = interp1(tableLddGrid, linspace(regs.FRMW.atlMinVbias1, regs.FRMW.atlMaxVbias1, nBins), lddVec);
        vBiasMat(2,:) = interp1(tableLddGrid, linspace(regs.FRMW.atlMinVbias2, regs.FRMW.atlMaxVbias2, nBins), lddVec);
        vBiasMat(3,:) = interp1(tableLddGrid, linspace(regs.FRMW.atlMinVbias3, regs.FRMW.atlMaxVbias3, nBins), lddVec);
    end
    if (size(vBiasMat,1) ~= 3)
        vBiasMat = vBiasMat';
    end
    % DSM X
    dvCal1 = regs.FRMW.atlMaxVbias1-regs.FRMW.atlMinVbias1;
    dvCal3 = regs.FRMW.atlMaxVbias3-regs.FRMW.atlMinVbias3;
    dv1 = vBiasMat(1,:) - regs.FRMW.atlMinVbias1;
    dv3 = vBiasMat(3,:) - regs.FRMW.atlMinVbias3;
    rowsForDsmX = (dv1*dvCal1+dv3*dvCal3)./(dvCal1^2 + dvCal3^2);
    rowsForDsmX = 1+(nBins-1)*min(max(rowsForDsmX,0),1);
    dsmValsX = interp1(1:nBins, algoThermalCalibData.table(:,[1,3]), vec(rowsForDsmX));
    dsmVals.xScale = dsmValsX(:,1);
    dsmVals.xOffset = dsmValsX(:,2);
    % DSM Y
    rowsForDsmY = (vBiasMat(2,:) - regs.FRMW.atlMinVbias2)/(regs.FRMW.atlMaxVbias2-regs.FRMW.atlMinVbias2);
    rowsForDsmY = 1+(nBins-1)*min(max(rowsForDsmY,0),1);
    dsmValsY = interp1(1:nBins, algoThermalCalibData.table(:,[2,4]), vec(rowsForDsmY));
    dsmVals.yScale = dsmValsY(:,1);
    dsmVals.yOffset = dsmValsY(:,2);
    
    rtdDataCol = 5;
else
    dsmVals = NaN;
    rtdDataCol = 1;
end

% RTD
rowsForRtd = (lddVec - tableLddRange(1))/(tableLddRange(2)-tableLddRange(1));
rowsForRtd = 1+(nBins-1)*min(max(rowsForRtd,0),1);
rtdVals = interp1(1:nBins, algoThermalCalibData.table(:,rtdDataCol), vec(rowsForRtd));
