function [success] = UpdateShortPresetRtdDiff_Calib_Calc(results)

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
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'results');
    end
    
    % operation
    if isfield(results,'rtd2add2short_state1') && isfield(results,'rtd2add2short_state2')
        runParams.outputFolder = output_dir;
        shortRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','shortRangePreset.csv');
        shortRangePreset = readtable(shortRangePresetFn);
        AlgoThermalLoopOffsetInd = find(strcmp(shortRangePreset.name,'AlgoThermalLoopOffset'));
        shortRangePreset.value(AlgoThermalLoopOffsetInd) = shortRangePreset.value(AlgoThermalLoopOffsetInd) + mean([results.rtd2add2short_state1,results.rtd2add2short_state2]);
        writetable(shortRangePreset,shortRangePresetFn);
        success = 1;
    else
        success = 0;
        fprintff('Failed to update rtd difference between long and short presets\n');
    end
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'success');
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
