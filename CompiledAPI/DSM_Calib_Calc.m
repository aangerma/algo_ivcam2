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

    im = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], false).i;
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'sz' , 'angxRawZOVec' , 'angyRawZOVec' ,'dsmregs_current' ,'calibParams');
    end
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'sz' , 'angxRawZOVec' , 'angyRawZOVec' ,'dsmregs_current' ,'calibParams');

    end
    
    [success, DSM_data, angxZO, angyZO] = DSM_Calib_Calc_int(im, sz, angxRawZOVec(:), angyRawZOVec(:), dsmregs_current, calibParams, fprintff);
    
    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'success', 'DSM_data','angxZO','angyZO');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nDSM_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

