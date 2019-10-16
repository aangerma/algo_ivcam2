function GenInitCalibTables_Calc(calibParams, eepromBin)
% description: the function should run in the beginning of calibration or re-calibration.
% inputs:
%   calibParams - struct with general params concerning calibration process
%   eepromBin   - BIN data with unit EEPROM (if exists and non-empty - ATC data will not be overriden).

    t0 = tic;
    global g_output_dir g_save_input_flag g_fprintff g_LogFn g_calib_dir g_countRuntime;

    % setting default global value in case not initial in the init function;
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
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

    % Scope definition
    if exist('eepromBin', 'var') && ~isempty(eepromBin)
        isATC = false;
        fprintff('Generating default tables for ACC calibration (preserving ATC tables).\n')
    else
        isATC = true;
        fprintff('Generating default tables for full calibration (overriding existing tables).\n')
    end

    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name '_in.mat']);
        if isATC
            save(fn, 'calibParams');
        else
            save(fn, 'calibParams', 'eepromBin');
        end
    end
    
    % Regs management
    fw = Pipe.loadFirmware(g_calib_dir);
    fw.get();
    if isATC
        vers = AlgoThermalCalibToolVersion;
    else
        vers = AlgoCameraCalibToolVersion;
    end
    verRegs.FRMW.calibVersion = uint32(hex2dec(single2hex(vers)));
    verRegs.FRMW.configVersion = uint32(hex2dec(single2hex(vers)));
    fw.setRegs(verRegs,'');
    if ~isATC % we're in ACC and should preserve ATC calibration results
        EPROMstructure  = load(fullfile(g_calib_dir,'eepromStructure.mat'));
        EPROMstructure  = EPROMstructure.updatedEpromTable;
        eepromBin       = uint8(eepromBin);
        eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
        [delayRegs, dsmRegs, thermalRegs, dfzRegs] = Calibraion.aux.getATCregsFromEEPROMregs(eepromRegs);
        fw.setRegs(delayRegs,'');
        fw.setRegs(dsmRegs,'');
        fw.setRegs(thermalRegs,'');
        fw.setRegs(dfzRegs,'');
    end
    
    % Generating tables from FW object and remaining tables which are not managed through actual FW regs
    outDir = fullfile(g_calib_dir, 'initialCalibFiles');
    fw.generateTablesForFw(outDir, 0, ~isATC, calibParams.tableVersions);
    rtdOverXTableFileName = Calibration.aux.genTableBinFileName('Algo_rtdOverAngX_CalibInfo', calibParams.tableVersions.algoRtdOverAngX);
    fw.writeRtdOverAngXTable(fullfile(outDir, rtdOverXTableFileName),[]);
    presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
    fw.writeDynamicRangeTable(fullfile(outDir, presetsTableFileName));
    rgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Calibration_Info_CalibInfo', calibParams.tableVersions.rgbCalib);
    writeAllBytes(zeros(1,112,'uint8'), fullfile(outDir, rgbTableFileName));

    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nGenInitCalibTables_Calc run time = %.1f[sec]\n', t1);
    end
end

