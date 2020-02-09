function [finishedHeating, calibPassed, results] = ThermalValidationDataFrame_Calc(finishedHeating, unitData, FrameData, sz, frameBytes, calibParams)



    t0 = tic;
    global g_output_dir g_save_input_flag g_save_output_flag g_countRuntime g_fprintff g_LogFn g_calib_dir g_skip_thermal_iterations_save g_temp_count;
    
    % auto-completions
    if isempty(g_temp_count)
        g_temp_count = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_skip_thermal_iterations_save)
        g_skip_thermal_iterations_save = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);

    % input save
    if ~g_skip_thermal_iterations_save && g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' ,[func_name sprintf('_in%d.mat',g_temp_count)]);
        save(fn,'finishedHeating', 'unitData', 'FrameData', 'sz', 'frameBytes', 'calibParams');
    end
    
    % operation
    origFinishedHeating = finishedHeating;
    
    try
        [finishedHeating, calibPassed ,results] = ThermalValidationDataFrame_Calc_int(finishedHeating, unitData, FrameData, sz, frameBytes, calibParams, output_dir, fprintff, g_calib_dir);
        if (calibPassed==-1) % save input for debugging
            if g_save_input_flag && exist(output_dir,'dir')~=0
                fn = fullfile(output_dir, 'mat_files' ,[func_name sprintf('_in%d.mat',g_temp_count)]);
                save(fn,'finishedHeating', 'unitData', 'FrameData', 'sz', 'frameBytes', 'calibParams');
            end
        end
    catch ME % save input for debugging
        if g_save_input_flag && exist(output_dir,'dir')~=0
            fn = fullfile(output_dir, 'mat_files' ,[func_name sprintf('_in%d.mat',g_temp_count)]);
            save(fn,'finishedHeating', 'unitData', 'FrameData', 'sz', 'frameBytes', 'calibParams');
        end
        rethrow(ME)
    end
    
    % output save
    if ~g_skip_thermal_iterations_save && g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,  'mat_files' ,[func_name sprintf('_out%d.mat',g_temp_count)]);
        save(fn, 'finishedHeating', 'calibPassed', 'results');
    end
    if (origFinishedHeating~=0)
        g_temp_count = 0;
    else
        g_temp_count = g_temp_count + 1; 
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

function [merged] = struct_merge(existing , new )
    merged = existing;
    % overriding merged with new
    f = fieldnames(new);
    for i = 1:length(f)
        fn = fieldnames(new.(f{i}));
        for n = 1:length(fn)
            merged.(f{i}).(fn{n}) = new.(f{i}).(fn{n});
        end
    end
end

