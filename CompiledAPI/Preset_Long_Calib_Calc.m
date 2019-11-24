function [isConverged, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(frameBytes, cameraInput, LaserPoints, maxMod_dec, curLaserPoint, calibParams)
% function [isConverged, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(frameBytes, cameraInput, LaserPoints, maxMod_dec, curLaserPoint, calibParams)
% description: 
%
% inputs:
%   frameBytes - images with different mod ref values (in bytes sequence form)
%   calibParams - calibparams strcture.
%   LaserPoints - 
%   maxMod_dec -
%   sz
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   

    t0 = tic;
    global g_output_dir g_save_input_flag g_save_output_flag g_countRuntime g_fprintff g_LogFn g_save_internal_input_flag g_laser_points g_scores;
    
    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_internal_input_flag)
        g_save_internal_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);
    
    % input save
    g_laser_points = [g_laser_points, curLaserPoint];
    g_scores = [g_scores, NaN];
    longRangestate =  Calibration.presets.findLongRangeStateCal(calibParams,cameraInput.imSize);
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name,'_', longRangestate, sprintf('_in%d.mat', length(g_laser_points))]);
        save(fn, 'frameBytes', 'cameraInput', 'LaserPoints', 'maxMod_dec', 'curLaserPoint', 'calibParams');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    maskParams = calibParams.presets.long.params;
    im = Calibration.aux.convertBytesToFrames(frameBytes, cameraInput.imSize, [], false);
        
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name,'_', longRangestate, sprintf('_int_in%d.mat', length(g_laser_points))]);
        mkdirSafe(fileparts(fn));
        save(fn, 'maskParams' ,'runParams', 'calibParams', 'longRangestate', 'im', 'cameraInput', 'LaserPoints', 'maxMod_dec', 'g_laser_points', 'g_scores', 'fprintff');
    end
    [isConverged, curScore, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc_int(maskParams, runParams, calibParams, longRangestate, im, cameraInput, LaserPoints, maxMod_dec, g_laser_points, g_scores, fprintff);
    
    g_scores(end) = curScore;
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name, '_', longRangestate, sprintf('_out%d.mat', length(g_laser_points))]);
        save(fn, 'isConverged', 'nextLaserPoint', 'maxRangeScaleModRef', 'maxFillRate', 'targetDist');
    end
    if (abs(isConverged)==1) % initialize globals for next resolution
        g_laser_points = [];
        g_scores = [];
    end
    
    % finalization
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\n%s run time = %.1f[sec]\n', func_name, t1);
    end
    if (fid>-1)
        fclose(fid);
    end
end



