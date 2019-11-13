function [success, DSM_data, angxZO, angyZO] = DSM_Calib_Calc(frameBytes, sz, angxRawZOVec, angyRawZOVec, dsmregs_current, calibParams)
    % description: initiale set of the DSM scale and offset
    %
    % inputs:
    %   angxRaw - <vcetor 32bit> raw x angle
    %   angyRaw - <vcetor 32bit> raw y angle
    %   calibParams - output from the cal_init
    % output:
    %   DSM_data.struct
    %       dsmXscale
    %       dsmXoffset
    %       dsmYscale
    %       dsmYoffset
    %
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
    if g_save_input_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'sz' , 'angxRawZOVec' , 'angyRawZOVec' ,'dsmregs_current' ,'calibParams');
    end
    
    % operation
    im = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], false).i;
    angxRawZOVec = angxRawZOVec(:);
    angyRawZOVec = angyRawZOVec(:);
    
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'sz', 'angxRawZOVec', 'angyRawZOVec', 'dsmregs_current', 'calibParams', 'fprintff');
    end
    [success, DSM_data, angxZO, angyZO] = DSM_Calib_Calc_int(im, sz, angxRawZOVec, angyRawZOVec, dsmregs_current, calibParams, fprintff);
    
    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'success', 'DSM_data', 'angxZO', 'angyZO');
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

