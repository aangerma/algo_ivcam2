function GenInitCalibTables_Calc(calibParams, eepromBin)
% description: the function should run in the beginning of calibration or re-calibration.
% inputs:
%   calibParams - struct with general params concerning calibration process
%   eepromBin - BIN data with unit EEPROM (if exists and non-empty - ATC data will not be overriden).

    global g_output_dir g_save_input_flag g_fprintff g_LogFn g_calib_dir;

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

    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name '_in.mat']);
        save(fn, 'calibParams', 'eepromBin');
    end

    % Scope definition
    if exists('eepromBin', 'var') && ~isempty(eepromBin)
        isATC = false;
        fprintff('Generating default tables for ACC calibration (preserving ATC tables).\n')
    else
        isATC = true;
        fprintff('Generating default tables for full calibration (overriding existing tables).\n')
    end

    % Regs extraction
    fw = Firmware(g_calib_dir);
    fw.get();
    EPROMstructure  = load(fullfile(g_calib_dir,'eepromStructure.mat'));
    EPROMstructure  = EPROMstructure.updatedEpromTable;
    eepromBin       = uint8(eepromBin);
    eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
    if isATC
        vers = AlgoThermalCalibToolVersion;
    else
        vers = AlgoCameraCalibToolVersion;
    end
    verRegs.FRMW.calibVersion = uint32(hex2dec(single2hex(vers)));
    verRegs.FRMW.configVersion = uint32(hex2dec(single2hex(vers)));
    [delayRegs, dsmRegs, thermalRegs, dfzRegs] = Calibraion.aux.getATCregsFromEEPROMregs(eepromRegs);
    
    % Setting regs in FW object
    fw.setRegs(verRegs,'');
    fw.setRegs(delayRegs,'');
    fw.setRegs(dsmRegs,'');
    fw.setRegs(thermalRegs,'');
    fw.setRegs(dfzRegs,'');
    
    % Generating tables from FW object and remaining tables which are not managed through actual FW regs
    outDir = fullfile(g_calib_dir, 'initialCalibFiles');
    fw.generateTablesForFw(outDir, 0, ~isATC, calibParams.tableVersions);
    rtdOverXTableFileName = Calibration.aux.genTableBinFileName('Algo_rtdOverAngX_CalibInfo', calibParams.tableVersions.algoRtdOverAngX);
    fw.writeRtdOverAngXTable(fullfile(outDir, rtdOverXTableFileName),[]);
    presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
    fw.writeDynamicRangeTable(fullfile(outDir, presetsTableFileName));
    rgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Calibration_Info_CalibInfo', calibParams.tableVersions.rgbCalib);
    writeAllBytes(zeros(1,112,'uint8'), fullfile(outDir, rgbTableFileName));

end

