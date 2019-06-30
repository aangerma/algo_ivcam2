function [rgbPassed,rgbTable,results] = RGB_Calib_Calc(InputPath,calibParams,irImSize,Kdepth,z2mm)
% description: initiale set of the DSM scale and offset 
%regs_reff
% inputs:
%   InputPath -  path for input images  dir stucture InputPath\PoseN N =1:5
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%                                  
% output:
%
   
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff; % g_regs g_luts;
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

    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath' , 'calibParams' ,'Kdepth' , 'z2mm','irImSize' );
    end
    [rgbPassed,rgbTable,results,im,rgbs] = Calibration.rgb.cal_rgb(InputPath,calibParams,irImSize,Kdepth,z2mm,fprintff);
    % save images
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_img.mat']);
        save(fn,'im','rgbs');
    end
    
    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'rgbPassed','rgbTable','results');
    end
    if(exist('fid','var'))
        fclose(fid);
    end

end

