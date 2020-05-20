function [dataForACTableGeneration] = readDataForK2DSM(hw)
dataForACTableGeneration.binWithHeaders = false;
[~,~, dataForACTableGeneration.acDataBin] = Calibration.tables.readCalibDataFromUnit(hw, 'Algo_AutoCalibration');% table 240
[~,~, dataForACTableGeneration.calibDataBin] = Calibration.tables.readCalibDataFromUnit(hw, 'Algo_Calibration_Info_CalibInfo'); % table 313
% dataForACTableGeneration.acDataBin = dataForACTableGeneration.acDataBin.tableData;
% dataForACTableGeneration.calibDataBin = dataForACTableGeneration.calibDataBin.tableData;

dataForACTableGeneration.DSMRegs.dsmXscale = hw.read('EXTLdsmXscale');
dataForACTableGeneration.DSMRegs.dsmYscale = hw.read('EXTLdsmYscale');
dataForACTableGeneration.DSMRegs.dsmXoffset = hw.read('EXTLdsmXoffset');
dataForACTableGeneration.DSMRegs.dsmYoffset = hw.read('EXTLdsmYoffset');
end

