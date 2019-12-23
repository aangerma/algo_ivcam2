function [newThermalData] = adjustRgbThermal2NewRefTemp(rgbThermalData,rgbCalibTemp,fprintff)
    newThermalData = rgbThermalData;
    if ~sum(rgbThermalData.thermalTable(:))
        fprintff('Thermal RGB table is not valid, no fix done\n');
         newThermalData.isValid = 0;
        return;
    end
    nBins = size(rgbThermalData.thermalTable,1);
    tempRange = [rgbThermalData.minTemp rgbThermalData.maxTemp];
    tempGridEdges = linspace(tempRange(1),tempRange(2),nBins+2);
    tempStep = tempGridEdges(2)-tempGridEdges(1);
    tempGrid = tempStep/2 + tempGridEdges(1:end-1);
    iForInverseTrans = find(abs(rgbCalibTemp-tempGrid) <= tempStep/2,1);
    if isempty(iForInverseTrans)
        fprintff('RGB calibration temperature is not in thermal fix range. RGB calibration temperature: %2.2f, thermal RGB table range: [%2.2f,%2.2f]\n',rgbCalibTemp,tempRange(1),tempRange(2));
        newThermalData.isValid = 0;
        return;
    end
    transMatFromCalibTemp =  [rgbThermalData.thermalTable(iForInverseTrans,1), -rgbThermalData.thermalTable(iForInverseTrans,2),0;...
                              rgbThermalData.thermalTable(iForInverseTrans,2), rgbThermalData.thermalTable(iForInverseTrans,1), 0;...
                              rgbThermalData.thermalTable(iForInverseTrans,3), rgbThermalData.thermalTable(iForInverseTrans,4), 1];
    if det(transMatFromCalibTemp) < eps
        fprintff('Thermal RGB matrix from calibration temperature is not invertible:  sc:%2.2f, ss:%2.2f, tx:%2.2f, ty:%2.2f\n',rgbThermalData.thermalTable(iForInverseTrans,1),rgbThermalData.thermalTable(iForInverseTrans,2),rgbThermalData.thermalTable(iForInverseTrans,3),rgbThermalData.thermalTable(iForInverseTrans,4));
        % Return identity
        newThermalData.isValid = 0;
        return;
    end
    for k = 1:nBins
        currentMat = [rgbThermalData.thermalTable(k,1), -rgbThermalData.thermalTable(k,2),0;...
                      rgbThermalData.thermalTable(k,2), rgbThermalData.thermalTable(k,1), 0;...
                      rgbThermalData.thermalTable(k,3), rgbThermalData.thermalTable(k,4), 1];
        newMat = currentMat/transMatFromCalibTemp;
        newThermalData.thermalTable(k,1) = newMat(1,1);
        newThermalData.thermalTable(k,2) = newMat(2,1);
        newThermalData.thermalTable(k,3) = newMat(3,1);
        newThermalData.thermalTable(k,4) = newMat(3,2);
    end
    newThermalData.referenceTemp = rgbCalibTemp;
    newThermalData.isValid = 1;
end

