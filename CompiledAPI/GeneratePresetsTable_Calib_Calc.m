function [presetsTableFullPath] = GeneratePresetsTable_Calib_Calc(calibParams)


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

    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir,'GeneratePresetsTable_temp');
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
        save(fn,'calibParams');
    end
    
    runParams.outputFolder = output_dir;
    presetPath = fullfile(runParams.outputFolder,'AlgoInternal');
    presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
    presetsTableFullPath = fullfile(runParams.outputFolder,'calibOutputFiles', presetsTableFileName);
    fw = Pipe.loadFirmware(presetPath);
    fw.writeDynamicRangeTable(presetsTableFullPath,presetPath);
    
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'presetsTableFullPath');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end