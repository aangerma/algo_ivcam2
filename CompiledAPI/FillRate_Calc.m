function results = FillRate_Calc(frameBytes, calibParams, res)
    % results = FillRate_Calc(frameBytes, calibParams, res)
    % description: Calculate Z fill rate within a given ROI
    % inputs:
    %   frameBytes - Z and I frames. As many as you wish.
    %   calibParams - Acc calib params. Used for 
    %   res - stream resolution (so we would know how to reshape the frameBytes)
    %
    % output:
    %   results - A struct that contains the average fill rate (amount of pixels with z>0) within the mask defined in calibParams accross the frames.
    %
    
    t0 = tic;
    global g_output_dir g_save_input_flag g_save_output_flag g_countRuntime g_fprintff g_LogFn g_save_internal_input_flag;
    
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
        save(fn, 'frameBytes', 'calibParams', 'res');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    im = Calibration.aux.convertBytesToFrames(frameBytes, res, [], false);
    
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'calibParams', 'runParams');
    end
    [results] = FillRate_Calc_int(im, calibParams, runParams);       
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'results');
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

