function [DSM_data] = DSM_CoarseCalib_Calc(angxRaw, angyRaw , calibParams)
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
    
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'angxRaw', 'angyRaw' ,'calibParams');
    end
    [rawXmin,rawXmax] = minmax_(angxRaw);
    [rawYmin,rawYmax] = minmax_(angyRaw);
    [DSM_data.dsmXscale,DSM_data.dsmXoffset] = stretch2margin(rawXmin,rawXmax, calibParams.coarseDSM.margin);
    [DSM_data.dsmYscale,DSM_data.dsmYoffset] = stretch2margin(rawYmin,rawYmax, calibParams.coarseDSM.margin);
    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'DSM_data');
    end
    if(exist('fid','var'))
        fclose(fid);
    end

end

function [scale,offset] = stretch2margin(rawMin,rawMax,margin)
    target = 2047 - margin;
    scale = single(2*target/(rawMax-rawMin));
    offset = single((target+2047)/scale - rawMax);
end
