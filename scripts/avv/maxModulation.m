function [maxRangeScaleModRef, maxFillRate, targetDist] = maxModulation(testParams, maskParams, fillRateTh ,output_folder, test)    
%     DEBUG    
%     testParams = struct('minModprc', '0', 'laserDelta', '1', 'framesNum', '10')
%     maskParams = struct('roi', '0.09', 'isRoiRect', '0', 'roiCropRect', '0', 'centerShiftX', '0', 'centerShiftY', '0')
%     fillRateTh = 97
%     output_folder = 'X:\Data\robot\08061017\debug\vga\long\280cm'
%     test = struct('name', 'vga', 'xRes', '640', 'yRes', '480', 'range', '280cm', 'preset', 'long', 'state', 'state2')
    
    testParams = converToDouble(testParams);    
    maskParams = converToDouble(maskParams); 
    test = converToDouble(test);    

    
    calibParams.presets.long.params = struct();
    calibParams.presets.long.params.roi = maskParams.roi;
    calibParams.presets.long.params.isRoiRect = maskParams.isRoiRect;
    calibParams.presets.long.params.roiCropRect = maskParams.roiCropRect; 
    calibParams.presets.long.params.maskCenterShift = [maskParams.centerShiftY maskParams.centerShiftX];
    calibParams.presets.long.updateCalibVal = 0
    
    calibParams.presets.long.(test.state).fillRateTh = str2double(fillRateTh);
    calibParams.presets.long.(test.state).updateCalibVal = 0;
    calibParams.errRange.(strcat('targetDist_', (test.state))) = [0 inf];
    
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
	if ~isfield(test, 'state')
        test.state='state2'
    end
    
    disp([test.yRes test.xRes])
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
    [maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(dataDir,cameraInput,laserPoints,maxMod_dec,calibParams,test.state);
	

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