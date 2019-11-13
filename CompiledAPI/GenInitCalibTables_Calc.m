function GenInitCalibTables_Calc(calibParams, outDir, eepromBin)
% description: the function should run in the beginning of calibration or re-calibration.
% inputs:
%   calibParams - struct with general params concerning calibration process
%   outDir      - directory for generating the default tables
%   eepromBin   - BIN data with unit EEPROM (if exists and non-empty - ATC data will not be overriden).

    t0 = tic;
    global g_output_dir g_save_input_flag g_fprintff g_LogFn g_calib_dir g_countRuntime;

    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);

    % Scope definition
    if exist('eepromBin', 'var') && ~isempty(eepromBin)
        isATC = false;
        fprintff('Generating default tables for ACC calibration (preserving ATC tables).\n');
    else
        isATC = true;
        fprintff('Generating default tables for full calibration (overriding existing tables).\n');
    end

    % input save
    if g_save_input_flag && (exist(g_output_dir,'dir')~=0)
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name '_in.mat']);
        if isATC
            save(fn, 'calibParams', 'outDir');
        else
            save(fn, 'calibParams', 'outDir', 'eepromBin');
        end
    end
    
    % operation
    if isempty(outDir)
        outDir = fullfile(g_calib_dir, 'initialCalibFiles');
    end
    if isATC
        vers = AlgoThermalCalibToolVersion;
        GenInitCalibTables_Calc_int(g_calib_dir, outDir, vers, calibParams.tableVersions)
    else
        vers = AlgoCameraCalibToolVersion;
        GenInitCalibTables_Calc_int(g_calib_dir, outDir, vers, calibParams.tableVersions, eepromBin)
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

