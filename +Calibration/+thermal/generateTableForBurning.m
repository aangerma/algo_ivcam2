function generateTableForBurning(eepromRegs, table,calibParams,runParams,fprintff,calibPassed,data,calib_dir)
% Creates a binary table as requested

% Thermal loop tables
calibData = struct('table', table);
binTable = Calibration.tables.convertCalibDataToBinTable(calibData, 'Algo_Thermal_Loop_CalibInfo');
thermalTableFileName = Calibration.aux.genTableBinFileName('Algo_Thermal_Loop_CalibInfo', calibParams.tableVersions.algoThermal);
thermalTableFullPath = fullfile(runParams.outputFolder, thermalTableFileName);
writeAllBytes(binTable, thermalTableFullPath);
fprintff('Generated algo thermal table full path:\n%s\n',thermalTableFullPath);

calibData = struct('tmptrOffsetValuesShort', data.tableResults.rtd.tmptrOffsetValuesShort);
binTable = Calibration.tables.convertCalibDataToBinTable(calibData, 'Algo_Thermal_Loop_Extra_CalibInfo');
extraThermalTableFileName = Calibration.aux.genTableBinFileName('Algo_Thermal_Loop_Extra_CalibInfo', calibParams.tableVersions.algoThermalExtras);
extraThermalTableFullPath = fullfile(runParams.outputFolder, extraThermalTableFileName);
writeAllBytes(binTable, extraThermalTableFullPath);
fprintff('Generated extra algo thermal table full path:\n%s\n',extraThermalTableFullPath);

% RGB thermal tabl
if isfield(data.tableResults, 'rgb')
    x = data.tableResults.rgb;
    calibData = struct('thermalTable', x.thermalTable, 'minTemp', x.minTemp, 'maxTemp', x.maxTemp, 'referenceTemp', x.referenceTemp, 'isValid', x.isValid);
    binTable = Calibration.tables.convertCalibDataToBinTable(calibData, 'RGB_Thermal_Info_CalibInfo');
    thermalRgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Thermal_Info_CalibInfo', calibParams.tableVersions.algoRgbThermal);
    thermalRgbTableFullPath = fullfile(runParams.outputFolder, thermalRgbTableFileName);
    writeAllBytes(binTable, thermalRgbTableFullPath);
    fprintff('Generated algo thermal RGB table full path:\n%s\n',thermalRgbTableFullPath);
end

% MEMS table (load and rewrite existing table from MEMS tester)
memsFile = dir(fullfile(calib_dir, 'MEMS_Electro_Optics_Calibration_Info_CalibInfo_Ver*.bin'));
assert(length(memsFile)==1, sprintf('Expecting 1 MEMS BIN file, found %d', length(memsFile)))
memsTableFileName = memsFile.name;
memsTableFullPath = fullfile(calib_dir, memsTableFileName);
calibData = Calibration.tables.readCalibDataFromTableFile(memsTableFullPath);
for iPzr = 1:3
    calibData.pzr(iPzr).humEstCoef = data.tableResults.pzr(iPzr).humEstCoef;
    calibData.pzr(iPzr).vsenseEstCoef = data.tableResults.pzr(iPzr).vsenseEstCoef;
end
calibData.ctKillThr = data.ctKillThr;
memsTableName = memsTableFileName(1:strfind(memsTableFileName, '_Ver')-1);
binTable = Calibration.tables.convertCalibDataToBinTable(calibData, memsTableName);
memsTableFullPath = fullfile(runParams.outputFolder, memsTableFileName);
writeAllBytes(binTable, memsTableFullPath);
fprintff('Generated MEMS table full path:\n%s\n',memsTableFullPath);

% All other algo tables
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
eepromRegs.FRMW.losAtMirrorRestHorz     = single(data.regs.FRMW.losAtMirrorRestHorz);
eepromRegs.FRMW.losAtMirrorRestVert     = single(data.regs.FRMW.losAtMirrorRestVert);
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

