function [maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(InputPath, cameraInput, LaserPoints, maxMod_dec, calibParams)
% function [dfzRegs,results,calibPassed] = Preset_Long_Calib_Calc(InputPath,LaserPoints,maxMod_dec,sz,calibParams)
% description: 
%
% inputs:
%   InputPath -  path for input images  dir stucture InputPath\PoseN N =1:5
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%   LaserPoints - 
%   maxMod_dec -
%   sz
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   

    t0 = tic;
    global g_output_dir g_calib_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn g_countRuntime; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_dummy_output_flag)
        g_dummy_output_flag = 0;
    end
    
    if isempty(g_calib_dir)
        g_dummy_output_flag = 0;
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
    longRangestate =  Calibration.presets.findLongRangeStateCal(calibParams,cameraInput.imSize);
    runParams.outputFolder = output_dir;
    maskParams = calibParams.presets.long.params;
    im = GetLongRangeImages(InputPath,cameraInput.imSize(2),cameraInput.imSize(1));
        
    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name,'_', longRangestate, '_in.mat']);
        save(fn,'InputPath','LaserPoints','maxMod_dec', 'cameraInput','calibParams','longRangestate');
        fn = fullfile(output_dir, 'mat_files' , [func_name,'_', longRangestate, '_int_in.mat']);
        mkdirSafe(fileparts(fn));
        save(fn,'im', 'maskParams' ,'runParams','calibParams','longRangestate','cameraInput','LaserPoints','maxMod_dec');
    end
    [maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc_int(maskParams, runParams, calibParams, longRangestate, im, cameraInput, LaserPoints, maxMod_dec, fprintff);
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name, longRangestate, '_out.mat']);
        save(fn,'maxRangeScaleModRef','maxFillRate','targetDist');
    end
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nPresete_Long_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

function [frames] = GetLongRangeImages(InputPath,width,height)
d = dir(InputPath);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
nameFolds = sort(nameFolds);
for k = 1:numel(nameFolds)
    path = fullfile(InputPath,nameFolds{k});
    frames(k).z = Calibration.aux.GetFramesFromDir(path,width, height,'Z');
    frames(k).i = Calibration.aux.GetFramesFromDir(path,width, height,'I');
end
end


