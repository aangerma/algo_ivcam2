function [Mcorrect] = getRgbThermalCorrectionMat(inputParams,inputTemp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function retrives the thermal correction table from bin file
% according to an input temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if inputParams.fromFile
    calibData = Calibration.tables.readCalibDataFromTableFile(inputParams.tablePath);
else
    [~, calibDataFlash] = Calibration.tables.readCalibDataFromUnit(inputParams.hw, inputParams.tableName); %???
    calibData = calibDataFlash.tableData;
end
if ~calibData.isValid
    warning('RGB thermal correction table is not valid, returning identity  matrix.');
    Mcorrect = eye(3,3);
    return;
end
tempRange = [calibData.minTemp calibData.maxTemp];
tempGridEdges = linspace(tempRange(1),tempRange(2),calibData.nBins+2);
tempStep = tempGridEdges(2)-tempGridEdges(1);
tempGrid = tempStep/2 + tempGridEdges(1:end-1);
ix = find(abs(inputTemp-tempGrid) <= tempStep/2,1);

Mcorrect = [calibData.thermalTable(ix,1), calibData.thermalTable(ix,2),calibData.thermalTable(ix,3);...
    -calibData.thermalTable(ix,2), calibData.thermalTable(ix,1),calibData.thermalTable(ix,4);...
    0, 0, 1];
end

