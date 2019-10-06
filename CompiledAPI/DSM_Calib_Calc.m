function [success, DSM_data,angxZO,angyZO] = DSM_Calib_Calc(path_spherical, sz , angxRawZOVec , angyRawZOVec ,dsmregs_current ,calibParams)
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
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn;
    
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

    width = sz(2);
    height = sz(1);
    im = Calibration.aux.GetFramesFromDir(path_spherical ,width , height);
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'path_spherical', 'sz' , 'angxRawZOVec' , 'angyRawZOVec' ,'dsmregs_current' ,'calibParams');
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'sz' , 'angxRawZOVec' , 'angyRawZOVec' ,'dsmregs_current' ,'calibParams');

    end
    
    [success, DSM_data,angxZO,angyZO] = DSM_Calib_Calc_int(im, sz , angxRawZOVec(:) , angyRawZOVec(:) ,dsmregs_current ,calibParams,fprintff);
    
    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'success', 'DSM_data','angxZO','angyZO');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

