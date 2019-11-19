function [data, calibPassed, results, metrics, metricsWithTheoreticalFix, Invalid_Frames] = finalCalcAfterHeating(data, eepromRegs, calibParams, fprintff, calib_dir, runParams)

invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);
data.dfzRefTmp = data.regs.FRMW.dfzCalTmp;
[table, results, Invalid_Frames] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);

if isempty(table)
    calibPassed = 0;
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
[fixedData] = Calibration.thermal.analyzeFramesOverTemperature(data.fixedData,calibParams,runParams,fprintff,1);
Calibration.aux.logResults(data.results, runParams);

%% merge all scores outputs
metrics = data.results;
metricsWithTheoreticalFix = fixedData.results;
calibPassed = Calibration.aux.mergeScores(data.results,calibParams.errRange,fprintff);

%% Burn 2 device
fprintff('Preparing thermal calibration data for burning\n');
Calibration.thermal.generateTableForBurning(eepromRegs, data.tableResults.table,calibParams,runParams,fprintff,0,data,calib_dir);
fprintff('Thermal calibration finished\n');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function results = UpdateResultsStruct(results)
    results.thermalRtdRefTemp       = results.rtd.refTemp;
    results.thermalMinCalTemp       = results.rtd.origMinval;
    results.thermalMaxCalTemp       = results.rtd.origMaxval;
    results.thermalMaSlope          = results.ma.slope;
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
    results.FRMWhumidApdTempDiff    = results.temp.FRMWhumidApdTempDiff;
    results = rmfield(results, {'rtd', 'ma', 'angy', 'angx', 'table', 'rgb', 'temp'});
end