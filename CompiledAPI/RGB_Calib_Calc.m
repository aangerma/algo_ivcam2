function [rgbPassed, rgbTable, results] = RGB_Calib_Calc(depthData, rgbData, calibParams, irImSize, Kdepth, z2mm)
% description: calculates the calibration between the IR/Depth images and
% the RGB images
%regs_reff
% inputs:
%   depthData - depth camera images (in binary sequence form)
%   rgbData - RGB camera images (in binary sequence form)
%   calibParams - calibparams strcture.
%                                  
% output:
% rgbPassed - <bool> Calibration suceeded 
% rgbTable - <vector> contains the data that will make the rgb table 
% results - <struct> with two interesting fields: rgbIntReprojRms,rgbExtReprojRms

    t0 = tic;
    global g_output_dir g_save_input_flag  g_save_internal_input_flag  g_save_output_flag  g_fprintff g_LogFn g_countRuntime; % g_regs g_luts;
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
    
    func_name = dbstack;
    func_name = func_name(1).name;
    
   if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(g_output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(g_output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
   end
    runParams.outputFolder = g_output_dir;

    im = Calibration.aux.convertBinDataToFrames(depthData, irImSize, doAverage, 'depth');
    rgbs = Calibration.aux.convertBinDataToFrames(rgbData, flip(calibParams.rgb.imSize), doAverage, 'rgb');
    
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'depthData', 'rgbData', 'calibParams', 'Kdepth', 'irImSize', 'z2mm');
    end
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn,'im' ,'rgbs', 'calibParams' ,'Kdepth' , 'runParams','runParams' ,'z2mm');
    end
    [rgbPassed, rgbTable, results] = RGB_Calib_Calc_int(im, rgbs, calibParams, Kdepth, fprintff, runParams, z2mm);

    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'rgbPassed','rgbTable','results');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nRGB_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

