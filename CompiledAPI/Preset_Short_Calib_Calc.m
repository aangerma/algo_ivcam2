function [minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(InputPath, LaserPoints, maxMod_dec, sz, calibParams)
% function [dfzRegs,results,calibPassed] = Preset_Short_Calib_Calc(InputPath,LaserPoints,maxMod_dec,sz,calibParams)
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
%                                  
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   
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
    width = sz(2);
    height = sz(1);
    im = GetMinRangeImages(InputPath,width,height);
    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath','LaserPoints','maxMod_dec', 'sz','calibParams');
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn,'im', 'LaserPoints' ,'maxMod_dec','sz','calibParams','output_dir','PresetFolder');
    end
    [minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc_int(im, LaserPoints, maxMod_dec, sz, calibParams, output_dir, PresetFolder);       

    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'minRangeScaleModRef','ModRefDec');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nPreset_Short_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

function [frames] = GetMinRangeImages(InputPath,width,height)
    d = dir(InputPath);
    isub = [d(:).isdir]; %# returns logical vector
    nameFolds = {d(isub).name}';
    nameFolds(ismember(nameFolds,{'.','..'})) = [];
    nameFolds = sort(nameFolds);
    for i = 1:numel(nameFolds)
        path = fullfile(InputPath,nameFolds{i});
        frames(i).i = Calibration.aux.GetFramesFromDir(path,width, height);
        frames(i).i = Calibration.aux.average_images(frames(i).i);
    end
    
    global g_output_dir g_save_input_flag; 
    if g_save_input_flag % save 
            fn = fullfile(g_output_dir,'mat_files' , 'MinRange_im.mat');
            save(fn,'frames');
    end
end

