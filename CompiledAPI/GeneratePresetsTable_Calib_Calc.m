function [presetsTableFullPath] = GeneratePresetsTable_Calib_Calc(calibParams)

    t0 = tic;
    global g_output_dir g_save_input_flag g_save_output_flag g_countRuntime g_fprintff g_LogFn;
    
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
        save(fn, 'calibParams');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    presetPath = fullfile(runParams.outputFolder,'AlgoInternal');
    presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
    presetsTableFullPath = fullfile(runParams.outputFolder,'calibOutputFiles', presetsTableFileName);
    initFolder = presetPath;
    fw = Pipe.loadFirmware(initFolder, 'tablesFolder', initFolder);
    fw.writeDynamicRangeTable(presetsTableFullPath,presetPath);
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'presetsTableFullPath');
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
