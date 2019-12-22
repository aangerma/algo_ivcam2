function generateTableForBurning(eepromRegs, table,calibParams,runParams,fprintff,calibPassed,data,calib_dir)
% Creates a binary table as requested

dsmTable = table(:,1:4);
rtdTable = table(:,5);
dsmTable = uint16(dsmTable*2^8);
rtdTable = typecast(int16(rtdTable*2^8),'uint16');
tableShifted = [dsmTable,rtdTable]; % FW expected format

thermalTableFileName = Calibration.aux.genTableBinFileName('Algo_Thermal_Loop_CalibInfo', calibParams.tableVersions.algoThermal);
thermalTableFullPath = fullfile(runParams.outputFolder, thermalTableFileName);
Calibration.thermal.saveThermalTable( tableShifted , thermalTableFullPath );
fprintff('Generated algo thermal table full path:\n%s\n',thermalTableFullPath);

if isfield(data.tableResults, 'rgb')
    rgbThermalTable = single(reshape(data.tableResults.rgb.thermalTable',[],1));
    rgbThermalTable = [data.tableResults.rgb.minTemp; data.tableResults.rgb.maxTemp; rgbThermalTable];
    thermalRgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Thermal_Info_CalibInfo', calibParams.tableVersions.algoRgbThermal);
    thermalRgbTableFullPath = fullfile(runParams.outputFolder, thermalRgbTableFileName);
    Calibration.thermal.saveRgbThermalTable( rgbThermalTable , thermalRgbTableFullPath );
    fprintff('Generated algo thermal RGB table full path:\n%s\n',thermalRgbTableFullPath);
end

initFldr = calib_dir;
fw = Pipe.loadFirmware(initFldr,'tablesFolder',calib_dir);

eepromRegs.FRMW.atlMinVbias1            = single(data.tableResults.angx.p0(1));
eepromRegs.FRMW.atlMaxVbias1            = single(data.tableResults.angx.p1(1));
eepromRegs.FRMW.atlMinVbias2            = single(data.tableResults.angy.minval);
eepromRegs.FRMW.atlMaxVbias2            = single(data.tableResults.angy.maxval);
eepromRegs.FRMW.atlMinVbias3            = single(data.tableResults.angx.p0(2));
eepromRegs.FRMW.atlMaxVbias3            = single(data.tableResults.angx.p1(2));
% AnaSync regs were updated in runAlgoThermalCalibration
eepromRegs.EXTL.conLocDelaySlow         = uint32(data.regs.EXTL.conLocDelaySlow);
eepromRegs.EXTL.conLocDelayFastC        = uint32(data.regs.EXTL.conLocDelayFastC);
eepromRegs.EXTL.conLocDelayFastF        = uint32(data.regs.EXTL.conLocDelayFastF);
eepromRegs.FRMW.conLocDelaySlowSlope    = single(data.regs.FRMW.conLocDelaySlowSlope);
eepromRegs.FRMW.conLocDelayFastSlope    = single(data.regs.FRMW.conLocDelayFastSlope);
% DSM regs were updated in AlgoThermalCalib
eepromRegs.EXTL.dsmXscale               = single(data.regs.EXTL.dsmXscale);
eepromRegs.EXTL.dsmXoffset              = single(data.regs.EXTL.dsmXoffset);
eepromRegs.EXTL.dsmYscale               = single(data.regs.EXTL.dsmYscale);
eepromRegs.EXTL.dsmYoffset              = single(data.regs.EXTL.dsmYoffset);
% Reference state regs were updated in AlgoThermalCalib
eepromRegs.FRMW.dfzCalTmp               = single(data.regs.FRMW.dfzCalTmp);
eepromRegs.FRMW.dfzVbias                = single(data.regs.FRMW.dfzVbias);
eepromRegs.FRMW.dfzIbias                = single(data.regs.FRMW.dfzIbias);
eepromRegs.FRMW.dfzApdCalTmp            = single(data.regs.FRMW.dfzApdCalTmp);
% Minimal and maximal mems angles in both axis
eepromRegs.FRMW.atlMinAngXL             = int16(data.dsmMovement.minX(1));
eepromRegs.FRMW.atlMinAngXR             = int16(data.dsmMovement.minX(2));
eepromRegs.FRMW.atlMaxAngXL             = int16(data.dsmMovement.maxX(1));
eepromRegs.FRMW.atlMaxAngXR             = int16(data.dsmMovement.maxX(2));
eepromRegs.FRMW.atlMinAngYU             = int16(data.dsmMovement.minY(1));
eepromRegs.FRMW.atlMinAngYB             = int16(data.dsmMovement.minY(2));
eepromRegs.FRMW.atlMaxAngYU             = int16(data.dsmMovement.maxY(1));
eepromRegs.FRMW.atlMaxAngYB             = int16(data.dsmMovement.maxY(2));
% RTD Slope for fix calculation using ma temperature + temperature difference for estimating TSense at low temperatures
eepromRegs.FRMW.atlSlopeMA              = single(data.tableResults.ma.slope);
eepromRegs.FRMW.atlMaCalTmp             = single(data.regs.FRMW.atlMaCalTmp);
eepromRegs.FRMW.humidApdTempDiff        = single(data.regs.FRMW.humidApdTempDiff);

fw.setRegs(eepromRegs,'');
fw.get();
fw.generateTablesForFw(runParams.outputFolder,1,[],calibParams.tableVersions);
end

