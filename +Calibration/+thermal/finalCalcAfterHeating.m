function [data, calibPassed, results, metrics, metricsWithTheoreticalFix, Invalid_Frames] = finalCalcAfterHeating(data, eepromRegs, calibParams, fprintff, calib_dir, runParams)

invalidFrames = arrayfun(@(x) isempty(x.ptsWithZ), data.framesData');
Invalid_Frames = sum(invalidFrames);
fprintff('Invalid frames: %.0f/%.0f\n', Invalid_Frames, numel(invalidFrames));
data.framesData = data.framesData(~invalidFrames);
% data.dfzRefTmp = data.regs.FRMW.dfzCalTmp;

% Seperate the short preset frames
longPreset = [data.framesData.presetMode] == 1;
data.framesDataShort = data.framesData(~longPreset);
data.framesData = data.framesData(longPreset);
if isempty(data.framesData) % To prevent confusion when running ATC with only short range preset
    data.framesData = data.framesDataShort;
end
data.dfzRefTmp =  data.framesData(end).temp.ldd;
% Generate short range table using long range data (better than default)
numberOfShortFrames = numel(data.framesDataShort);
if numberOfShortFrames ~= 4 % Required number of short preset frames
    nLong = numel(data.framesData);
    data.framesDataShort = data.framesData(round(linspace(1,nLong,4)));
end

[table, results, errorCode] = Calibration.thermal.generateFWTable(data, calibParams, runParams, fprintff);

if isempty(table) || ~isnan(errorCode)
    calibPassed = errorCode;
    metrics = [];
    metricsWithTheoreticalFix = [];
    fprintff('Error: table is empty (generateFWTable aborted)\n');
    return;
end

data.tableResults = results;
[data] = Calibration.thermal.applyThermalFix(data,data.regs,[],calibParams,runParams,1);
results.yDsmLosDegredation = data.tableResults.yDsmLosDegredation;
results = UpdateResultsStruct(results); % output single layer results struct
data.regs.FRMW.humidApdTempDiff = results.FRMWhumidApdTempDiff;

[data] = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,0);
calibParamsFixed = calibParams;
if isfield(calibParams.gnrl, 'rgb') && isfield(calibParams.gnrl.rgb, 'doStream') && calibParams.gnrl.rgb.doStream
    calibParamsFixed.gnrl.rgb.doStream = 0; %No need to plot RGB plots twice
end
[fixedData] = Calibration.thermal.analyzeFramesOverTemperature(data.fixedData,calibParamsFixed,runParams,fprintff,1);
Calibration.aux.logResults(data.results, runParams);

%% merge all scores outputs
metrics = data.results;
metricsWithTheoreticalFix = fixedData.results;
calibPassed = Calibration.aux.mergeScores(data.results,calibParams.errRange,fprintff);

%% Burn 2 device
fprintff('Preparing thermal calibration data for burning\n');
generateTableForBurning(eepromRegs, calibParams, runParams, fprintff, data, calib_dir);
fprintff('Thermal calibration finished\n');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function results = UpdateResultsStruct(results)
    % RTD results
    results.thermalRtdRefTemp       = results.rtd.refTemp;
    results.thermalMinCalTemp       = results.rtd.origMinval;
    results.thermalMaxCalTemp       = results.rtd.origMaxval;
    if isfield(results.rtd, 'modelsRmsRatio')
        results.rtdModelsRmsRatio   = results.rtd.modelsRmsRatio;
        results.rtdModelOrder       = results.rtd.modelOrder;
    end
    results.thermalMaSlope          = results.ma.slope;
    % LOS results
    results.thermalAngyMinAbsScale  = min(abs(results.angy.scale));
    results.thermalAngyMaxAbsScale  = max(abs(results.angy.scale));
    results.thermalAngyMinAbsOffset = min(abs(results.angy.offset));
    results.thermalAngyMaxAbsOffset = max(abs(results.angy.offset));
    results.thermalAngyMinVal       = results.angy.minval;
    results.thermalAngyMaxVal       = results.angy.maxval;
    results.thermalAngxMinAbsScale  = min(abs(results.angx.scale));
    results.thermalAngxMaxAbsScale  = max(abs(results.angx.scale));
    results.thermalAngxMinAbsOffset = min(abs(results.angx.offset));
    results.thermalAngxMaxAbsOffset = max(abs(results.angx.offset));
    results.thermalAngxP0x          = results.angx.p0(1);
    results.thermalAngxP0y          = results.angx.p0(2);
    results.thermalAngxP1x          = results.angx.p1(1);
    results.thermalAngxP1y          = results.angx.p1(2);
    % Tmptr results
    results.FRMWhumidApdTempDiff    = results.temp.FRMWhumidApdTempDiff;
    % Struct cleaning
    if isfield(results, 'rgb')
        results = rmfield(results, {'rtd', 'ma', 'angy', 'angx', 'table', 'pzr', 'rgb', 'temp'});
    else
        results = rmfield(results, {'rtd', 'ma', 'angy', 'angx', 'table', 'pzr', 'temp'});
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function generateTableForBurning(eepromRegs, calibParams, runParams, fprintff, data, calib_dir)
    % Creates a binary table as requested
    
    % Thermal loop tables
    calibData = struct('table', data.tableResults.table);
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
    
    % RGB thermal table
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
    fw = Pipe.loadFirmware(initFldr, 'tablesFolder', calib_dir);
    
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
    fw.generateTablesForFw(runParams.outputFolder, 1, [], calibParams.tableVersions);
end

