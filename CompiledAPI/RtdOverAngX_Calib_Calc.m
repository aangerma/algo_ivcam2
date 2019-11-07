function [tablefn] = RtdOverAngX_Calib_Calc(depthDataConstant, depthDataSteps, calibParams, regs, luts)

    t0 = tic;
    global g_output_dir g_save_input_flag  g_save_internal_input_flag  g_save_output_flag  g_fprintff g_LogFn g_countRuntime;
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

    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir,'RtdOverAngX_temp');
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

    
    runParams.outputFolder = output_dir;
    width = regs.GNRL.imgHsize;
    height = regs.GNRL.imgVsize;
    imConstant = Calibration.aux.convertBinDataToFrames(depthDataConstant, [height, width], true, 'depth').z;
    imSteps = Calibration.aux.convertBinDataToFrames(depthDataSteps, [height, width], true, 'depth').z;
    
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'depthDataConstant', 'depthDataSteps', 'calibParams' ,'regs','luts');
    end
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn,'imConstant','imSteps', 'calibParams' ,'regs','luts','runParams');
    end
    [tablefn] = RtdOverAngX_Calib_Calc_int(imConstant, imSteps, calibParams, regs, luts, runParams);
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'tablefn');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nRtdOverAngX_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end
