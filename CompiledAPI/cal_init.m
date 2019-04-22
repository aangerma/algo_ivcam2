function [calibParams , result] = cal_init(output_dir, calib_params_fn, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag ,fprintff )
% descrition :
%   this function configured the all calibration mode of work, initiate
%   global variable for all cal function use.
%   inputs:
%   output_dir          - <string> directory for all outputs (saved images , logs , output results ...
%   calib_params_fn     - <string> path of XML file include all calib_params 
%   debug_log_f         - <bool> 1 to output log file pf the run. 
%   verbose             - <uint> 1 to 5 varbositty level.
%   save_input_flag     - <bool> 1 record all input params of all cal functions  
%   save_output_flag    - <bool> 1 record all outputs of all cal functions
%   dummy_output_flag   - <bool> 1 autuo generate / from files output for tester flow debug. 
%   
%   outputs:
%       result      - <bool> 1- success 0 - fail
%

%    global g_calib_params_fn g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprinff ;
%    g_calib_params_fn       = calib_params_fn;


    clear delay_R_calib_calc;   % persistance variable in function.
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff ;
    g_output_dir            = output_dir;
    g_debug_log_f           = debug_log_f;
    g_verbose               = verbose;
    g_save_input_flag       = save_input_flag;
    g_save_output_flag      = save_output_flag;
    g_dummy_output_flag     = dummy_output_flag;
    
    if (g_debug_log_f)
        fn = fullfile(g_output_dir,'cal_log.txt');
        fid = fopen(fn,'w');
        cal_print = @(varargin) fprintf(fid,varargin{:});
    else
        cal_print = @(varargin) dummy_print(varargin{:});
    end
    
    if(~exist('fprintff','var'))
        g_fprintff = cal_print;
    else
        g_fprintff = fprintff;
    end
    fprintff = g_fprintff; 
    
    mkdirSafe(output_dir);
    result = 1;
    if (g_debug_log_f)
        fprintff('output_dir = %s   \n'        ,output_dir);
        fprintff('g_debug_log_f = %d  \n'      ,g_debug_log_f);
        fprintff('g_verbose = %d  \n'          ,g_verbose);
        fprintff('g_save_input_flag = %d  \n'  ,g_save_input_flag);
        fprintff('g_save_output_flag = %d  \n' ,g_save_output_flag);
        fprintff('g_dummy_output_flag = %d  \n',g_dummy_output_flag);
    end
    
    % load calib params from.XML  
    if exist(calib_params_fn, 'file')
        calibParams = xml2structWrapper(calib_params_fn);
    else
        calibParams = 0;
        result = 0;
    end
    if exist('fid','var')   
        fclose(fid);
    end

    return;
end


function dummy_print(varargin)
    return;
end