function [calibParams, result] = cal_init(output_dir, calib_dir, calib_params_fn, save_input_flag, save_internal_input_flag, save_output_flag, skip_thermal_iterations_save, fprintff)
% descrition :
%   this function configured the all calibration mode of work, initiate
%   global variable for all cal function use.
%   inputs:
%   output_dir               - <string> directory for all outputs (saved images , logs , output results ...
%   calib_dir                - path to calibration folder
%   calib_params_fn          - <string> path of XML file include all calib_params 
%   save_input_flag          - <bool> 1 record all input params of all cal functions  
%   save_internal_input_flag - <bool> 1 record all input params of all cal internal functions  
%   save_output_flag         - <bool> 1 record all outputs of all cal functions
%   
%   outputs:
%       result      - <bool> 1- success 0 - fail
%

    t0 = tic;
    global g_output_dir g_calib_dir g_save_input_flag g_save_internal_input_flag g_save_output_flag g_skip_thermal_iterations_save g_fprintff g_delay_cnt acc g_LogFn g_temp_count g_countRuntime;

    % initializations
    g_delay_cnt                     = 0;
    g_calib_dir                     = calib_dir;
    g_output_dir                    = output_dir;
    g_save_input_flag               = save_input_flag;
    g_save_output_flag              = save_output_flag;
    g_save_internal_input_flag      = save_internal_input_flag;
    g_skip_thermal_iterations_save  = skip_thermal_iterations_save;
    acc                             = [];
    g_temp_count                    = 0;
    g_countRuntime                  = 1;
    mkdirSafe(output_dir);
    mkdirSafe(fullfile(output_dir, 'mat_files'));
    
    % input save
    func_name = dbstack;
    func_name = func_name(1).name;
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' ,[func_name '_in.mat']);
        if(~exist('fprintff','var'))
            save(fn, 'output_dir', 'calib_dir', 'calib_params_fn', 'save_input_flag', 'save_internal_input_flag', 'save_output_flag', 'skip_thermal_iterations_save');
        else
            save(fn, 'output_dir', 'calib_dir', 'calib_params_fn', 'save_input_flag', 'save_internal_input_flag', 'save_output_flag', 'skip_thermal_iterations_save', 'fprintff');
        end
    end
    
    % operation
    if(~exist('fprintff','var'))
        g_LogFn = fullfile(g_output_dir,'cal_log.txt');
        fid = fopen(g_LogFn,'w');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else
        fid = -1;
        g_fprintff = fprintff;
    end

    result = 1;
    fprintff('<< Algo calibration version: %.2f >>\n', AlgoCameraCalibToolVersion);
    if (0)
        fprintff('output_dir = %s   \n'        ,output_dir);
        fprintff('g_save_input_flag = %d  \n'  ,g_save_input_flag);
        fprintff('g_save_output_flag = %d  \n' ,g_save_output_flag);
    end
    
    if exist(calib_params_fn, 'file') % load calib params from.XML  
        calibParams = xml2structWrapper(calib_params_fn);
    else
        calibParams = 0;
        result = 0;
    end
    
    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir,  'mat_files' ,[func_name '_out.mat']);
        save(fn, 'calibParams', 'result');
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

