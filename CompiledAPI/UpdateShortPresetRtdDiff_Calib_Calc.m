function [success] = UpdateShortPresetRtdDiff_Calib_Calc(results)

    t0 = tic;
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn g_countRuntime;
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

    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir,'UpdateShortPresetRtdDiff_temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end

    
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'results');
    end
    %%%%%%%%%%
    if isfield(results,'rtd2add2short_state1') && isfield(results,'rtd2add2short_state2')
        runParams.outputFolder = output_dir;
        shortRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','shortRangePreset.csv');
        shortRangePreset=readtable(shortRangePresetFn);
        AlgoThermalLoopOffsetInd=find(strcmp(shortRangePreset.name,'AlgoThermalLoopOffset'));
        shortRangePreset.value(AlgoThermalLoopOffsetInd) = shortRangePreset.value(AlgoThermalLoopOffsetInd) + mean([results.rtd2add2short_state1,results.rtd2add2short_state2]);
        writetable(shortRangePreset,shortRangePresetFn);
        success = 1;
    else
        success = 0;
        fprintff('Failed to update rtd difference between long and short presets\n');
    end
    
    
    %%%%%%%%%%
    
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'success');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nUpdateShortPresetRtdDiff_Calib_Calc run time = %.1f[sec]\n', t1);
    end
end
