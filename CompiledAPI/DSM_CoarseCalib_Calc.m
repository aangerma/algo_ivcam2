function [DSM_data] = DSM_CoarseCalib_Calc(angxRaw, angyRaw, calibParams)
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
    global g_output_dir g_save_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;
    
    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
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
        save(fn, 'angxRaw', 'angyRaw' ,'calibParams');
    end
    
    % operation
    [rawXmin,rawXmax] = minmax_(angxRaw);
    [rawYmin,rawYmax] = minmax_(angyRaw);
    [DSM_data.dsmXscale,DSM_data.dsmXoffset] = stretch2margin(rawXmin,rawXmax, calibParams.coarseDSM.margin);
    [DSM_data.dsmYscale,DSM_data.dsmYoffset] = stretch2margin(rawYmin,rawYmax, calibParams.coarseDSM.margin);
    
    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'DSM_data');
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scale,offset] = stretch2margin(rawMin,rawMax,margin)
    target = 2047 - margin;
    scale = single(2*target/(rawMax-rawMin));
    offset = single((target+2047)/scale - rawMax);
end

