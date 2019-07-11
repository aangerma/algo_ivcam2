function [  ] = updatePresetsEndOfCalibration( calibParams,presetPath,regs ,results)
    longRangePresetFn = fullfile(presetPath,'longRangePreset.csv');
    longRangePreset=readtable(longRangePresetFn);
    shortRangePresetFn = fullfile(presetPath,'shortRangePreset.csv');
    shortRangePreset=readtable(shortRangePresetFn);
    
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'JFILinvMinMax',calibParams.presets.long.JFILinvMinMax);
    
    systemDelay = regs.DEST.txFRQpd(1);
    coarseMaskingValueLR = Calibration.aux.maskDistancesWithCoarseMasking(regs,systemDelay, calibParams.presets.long.coarseMaskingRange);
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'DCORcoarseMasking_002',coarseMaskingValueLR);
    if isfield(results,'rtdDiffBetweenPresets')
        shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'AlgoThermalLoopOffset',results.rtdDiffBetweenPresets);
        systemDelay = systemDelay - results.rtdDiffBetweenPresets;
        
    end
    coarseMaskingValueSR = Calibration.aux.maskDistancesWithCoarseMasking(regs,systemDelay, calibParams.presets.short.coarseMaskingRange);
    shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'DCORcoarseMasking_002',coarseMaskingValueSR);
    
    
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'JFILgammaScale',uint32(calibParams.presets.long.JFILgammaScale));
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'JFILgammaShift',uint32(calibParams.presets.long.JFILgammaShift));
    shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'JFILgammaScale',uint32(calibParams.presets.short.JFILgammaScale));
    shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'JFILgammaShift',uint32(calibParams.presets.short.JFILgammaShift));
    
    writetable(longRangePreset,longRangePresetFn);
    writetable(shortRangePreset,shortRangePresetFn);


end

function presetTable = updatePresetTableByFieldName(presetTable,fname,value)
    fieldInd=find(strcmp(presetTable.name,fname));
    presetTable.value(fieldInd) = value;
end