function [isConverged, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(depthData, cameraInput, LaserPoints, maxMod_dec, curLaserPoint, calibParams)
% function [isConverged, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(depthData, cameraInput, LaserPoints, maxMod_dec, curLaserPoint, calibParams)
% description: 
%
% inputs:
%   depthData - images with different mod ref values (in binary sequence form)
%   calibParams - calibparams strcture.
%   LaserPoints - 
%   maxMod_dec -
%   sz
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   

    t0 = tic;
    global g_output_dir g_calib_dir g_save_input_flag  g_save_internal_input_flag  g_save_output_flag  g_fprintff g_LogFn g_countRuntime; % g_regs g_luts;
    global g_laser_points g_scores
    % setting default global value in case not initial in the init function;
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_internal_input_flag)
        g_save_internal_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end

    calib_dir = g_calib_dir;
    PresetFolder = calib_dir;
    
    func_name = dbstack;
    func_name = func_name(1).name;
    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end
    
    g_laser_points = [g_laser_points, curLaserPoint];
    g_scores = [g_scores, NaN];
    
    longRangestate =  Calibration.presets.findLongRangeStateCal(calibParams,cameraInput.imSize);
    runParams.outputFolder = output_dir;
    maskParams = calibParams.presets.long.params;
    
    im = Calibration.aux.convertBinDataToFrames(depthData, cameraInput.imSize, false, 'depth');
        
    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name,'_', longRangestate, sprintf('_in%d.mat', length(g_laser_points))]);
        save(fn,'depthData', 'cameraInput', 'LaserPoints', 'maxMod_dec', 'curLaserPoint', 'calibParams');
    end
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name,'_', longRangestate, sprintf('_int_in%d.mat', length(g_laser_points))]);
        mkdirSafe(fileparts(fn));
        save(fn,'im', 'maskParams' ,'runParams','calibParams','longRangestate','cameraInput','LaserPoints','maxMod_dec','g_laser_points', 'g_scores', 'fprintff');
    end
    [isConverged, curScore, nextLaserPoint, maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc_int(maskParams, runParams, calibParams, longRangestate, im, cameraInput, LaserPoints, maxMod_dec, g_laser_points, g_scores, fprintff);
    g_scores(end) = curScore;
    if (abs(isConverged)==1) % initialize globals for next resolution
        g_laser_points = [];
        g_scores = [];
    end
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name, '_', longRangestate, sprintf('_out%d.mat', length(g_laser_points))]);
        save(fn, 'isConverged', 'nextLaserPoint', 'maxRangeScaleModRef', 'maxFillRate', 'targetDist');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nPreset_Long_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end



