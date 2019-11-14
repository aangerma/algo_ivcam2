function tablefn = RtdOverAngX_Calib_Calc(frameBytesConstant, frameBytesSteps, calibParams, regs, luts)

    t0 = tic;
    global g_output_dir g_save_input_flag g_save_internal_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;
    
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
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytesConstant', 'frameBytesSteps', 'calibParams', 'regs', 'luts');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    width = regs.GNRL.imgHsize;
    height = regs.GNRL.imgVsize;
    imConstant = Calibration.aux.convertBytesToFrames(frameBytesConstant, [height, width], [], true).z;
    imSteps = Calibration.aux.convertBytesToFrames(frameBytesSteps, [height, width], [], true).z;
    
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'imConstant', 'imSteps', 'calibParams', 'regs', 'luts', 'runParams');
    end
    [tablefn] = RtdOverAngX_Calib_Calc_int(imConstant, imSteps, calibParams, regs, luts, runParams);
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'tablefn');
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
