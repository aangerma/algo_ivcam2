function [  ] = updatePresetsEndOfCalibration( calibParams,presetPath ,results)
    longRangePresetFn = fullfile(presetPath,'longRangePreset.csv');
    longRangePreset=readtable(longRangePresetFn);
    shortRangePresetFn = fullfile(presetPath,'shortRangePreset.csv');
    shortRangePreset=readtable(shortRangePresetFn);
    
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'JFILinvMinMax',calibParams.presets.long.JFILinvMinMax);
    shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'JFILinvMinMax',calibParams.presets.short.JFILinvMinMax);

    
    LRdistRange=calibParams.presets.long.coarseMaskingRange; 
    LRminRange = LRdistRange(1);
    LRmaxRange = LRdistRange(2);
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'coarse_masking_min',uint16(LRminRange));
    longRangePreset = updatePresetTableByFieldName(longRangePreset,'coarse_masking_max',uint16(LRmaxRange));
    
    if isfield(results,'rtdDiffBetweenPresets')
        shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'AlgoThermalLoopOffset',results.rtdDiffBetweenPresets);
    end
    SRdistRange=calibParams.presets.short.coarseMaskingRange; 
    SRminRange = SRdistRange(1);
    SRmaxRange = SRdistRange(2);
    shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'coarse_masking_min',uint16(SRminRange));
    shortRangePreset = updatePresetTableByFieldName(shortRangePreset,'coarse_masking_max',uint16(SRmaxRange));
    
    
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