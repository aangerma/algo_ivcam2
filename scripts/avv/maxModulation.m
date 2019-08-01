function [maxRangeScaleModRef, maxFillRate, targetDist] = maxModulation(testParams, maskParams, fillRateTh ,output_folder, test)    
    testParams = converToDouble(testParams);    
    maskParams = converToDouble(maskParams); 
    test = converToDouble(test);    
    
    calibParams.presets.long.params = struct();
    calibParams.presets.long.params.roi = maskParams.roi;
    calibParams.presets.long.params.isRoiRect = maskParams.isRoiRect;
    calibParams.presets.long.params.roiCropRect = maskParams.roiCropRect; 
    calibParams.presets.long.params.maskCenterShift = [maskParams.centerShiftY maskParams.centerShiftX];
    
    calibParams.presets.long.fillRateTh = str2double(fillRateTh);
    calibParams.presets.long.updateCalibVal = 0;
    calibParams.errRange.targetDist = [0 inf];
    
    global g_fprintff  g_calib_dir g_output_dir;
    g_fprintff = @fprintf;
    g_calib_dir = output_folder;
    g_output_dir = output_folder;
    
    
    hw = HWinterface();
    
    if isfield(test, 'preStreamCmd')
        runCmd(hw, test.preStreamCmd);
    end
    if isfield(test, 'preset')
        setPreset(hw, test.preset)
    end
    
    if isfield(test,'xRes') && isfield(test,'yRes')
        hw.startStream(0, [test.yRes test.xRes]);
    else
        hw.startStream();
    end
    
    if isfield(test, 'postStreamCmd')
        runCmd(hw, test.postStreamCmd);
    end
    
    dataDir = fullfile(output_folder, 'data');
    mkdirSafe(dataDir);
    [laserPoints,maxMod_dec] = Calibration.presets.captureVsLaserMod(hw,testParams.minModprc,testParams.laserDelta,testParams.framesNum,dataDir);
    cameraInput.z2mm = hw.z2mm;
    cameraInput.imSize = double(hw.streamSize);
    [maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(dataDir,cameraInput,laserPoints,maxMod_dec,calibParams);

end

function s = converToDouble(s)
    f = fieldnames(s);
    for i = 1:length(f)
        if ~isnan(str2double(s.(f{i})))
            s.(f{i}) = str2double(s.(f{i}));
        end
    end
end

function setPreset(hw, preset)
    if strcmpi(preset, 'long')
        val = 1;
    elseif strcmpi(preset, 'short')
        val = 2;
    else
        error('cant recognize preset: %s', preset) 
    end
    
    hw.setPresetControlState(val)
end

function runCmd(hw, cmd)
    commands = split(cmd,',');
    for i = 1:length(commands)
        result = hw.runScript(commands{i});
        if ~result.IsCompletedOk
            error('failed running command: %s', commands{i});
        end
    end
end