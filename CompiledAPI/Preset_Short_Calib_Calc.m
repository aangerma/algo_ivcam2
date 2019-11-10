function [isConverged, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(frameBytes, LaserPoints, maxMod_dec, curLaserPoint, sz, calibParams)
% function [minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(frameBytes, LaserPoints, maxMod_dec, curLaserPoint, sz, calibParams)
% description: 
%
% inputs:
%   frameBytes - images with different mod ref values (in bytes sequence form)
%   calibParams - calibparams strcture.
%   LaserPoints - 
%   maxMod_dec -
%   sz
%                                  
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   
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
    g_scores = [g_scores, NaN(3,1)];
    
    im = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], true);
    
    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'LaserPoints', 'maxMod_dec', 'curLaserPoint', 'sz','calibParams');
    end
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn,'im', 'LaserPoints' ,'maxMod_dec','sz','calibParams','output_dir','PresetFolder');
    end
    [isConverged, curScore, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc_int(im, LaserPoints, maxMod_dec, sz, calibParams, output_dir, PresetFolder, g_laser_points, g_scores);       
    g_scores(:,end) = curScore;
    if (abs(isConverged)==1)
        g_laser_points = [];
        g_scores = [];
    end
    
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'isConverged', 'nextLaserPoint', 'minRangeScaleModRef', 'ModRefDec');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nPreset_Short_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end


