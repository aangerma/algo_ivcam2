function [transMat, relevantRow] = calcRgbThermalTransMat(rgbThermalCalibData, humTemp)

nBins = size(rgbThermalCalibData.thermalTable,1);
tempRange = [rgbThermalCalibData.minTemp rgbThermalCalibData.maxTemp];
tempGridEdges = linspace(tempRange(1),tempRange(2),nBins+2);
tempStep = tempGridEdges(2)-tempGridEdges(1);
tempGrid = tempStep/2 + tempGridEdges(1:end-1);
relevantRow = find(abs(humTemp-tempGrid) <= tempStep/2,1);
if isempty(relevantRow)
    transMat = NaN(3,3);
    return;
end
transMat =  [rgbThermalCalibData.thermalTable(relevantRow,1), -rgbThermalCalibData.thermalTable(relevantRow,2),0;...
             rgbThermalCalibData.thermalTable(relevantRow,2), rgbThermalCalibData.thermalTable(relevantRow,1), 0;...
             rgbThermalCalibData.thermalTable(relevantRow,3), rgbThermalCalibData.thermalTable(relevantRow,4), 1];
