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


[table, results, errorCode] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);

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
Calibration.thermal.generateTableForBurning(eepromRegs, data.tableResults.table,calibParams,runParams,fprintff,0,data,calib_dir);
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
    % PZR results
    results.pzr1x2Coef              = results.pzr(1).coef(1);
    results.pzr1x1Coef              = results.pzr(1).coef(2);
    results.pzr1x0Coef              = results.pzr(1).coef(3);
    results.pzr2x2Coef              = results.pzr(2).coef(1);
    results.pzr2x1Coef              = results.pzr(2).coef(2);
    results.pzr2x0Coef              = results.pzr(2).coef(3);
    results.pzr3x2Coef              = results.pzr(3).coef(1);
    results.pzr3x1Coef              = results.pzr(3).coef(2);
    results.pzr3x0Coef              = results.pzr(3).coef(3);
    % Tmptr results
    results.FRMWhumidApdTempDiff    = results.temp.FRMWhumidApdTempDiff;
    % Struct cleaning
    if isfield(results, 'rgb')
        results = rmfield(results, {'rtd', 'ma', 'angy', 'angx', 'table', 'pzr', 'rgb', 'temp'});
    else
        results = rmfield(results, {'rtd', 'ma', 'angy', 'angx', 'table', 'pzr', 'temp'});
    end
end