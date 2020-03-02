function GenInitCalibTables_Calc_int(initFolder, outFolder, calibToolVers, tableVersions, eepromBin)

    preserveThermalCalib = exist('eepromBin', 'var');
    
    % Regs management
    fw = Pipe.loadFirmware(initFolder,'tablesFolder',initFolder);
    fw.get();
    verRegs.FRMW.calibVersion = uint32(hex2dec(single2hex(calibToolVers)));
    verRegs.FRMW.configVersion = uint32(hex2dec(single2hex(calibToolVers)));
    fw.setRegs(verRegs,'');
    if preserveThermalCalib
        EPROMstructure  = load(fullfile(initFolder,'eepromStructure.mat'));
        EPROMstructure  = EPROMstructure.updatedEpromTable;
        eepromBin       = uint8(eepromBin);
        eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
        if (eepromRegs.FRMW.dfzCalTmp==0) % no thermal calibration to preserve
            error('ACC has started, while ATC data is missing!')
        end
        [delayRegs, dsmRegs, thermalRegs, dfzRegs] = Calibration.aux.getATCregsFromEEPROMregs(eepromRegs);
        fw.setRegs(delayRegs,'');
        fw.setRegs(dsmRegs,'');
        fw.setRegs(thermalRegs,'');
        fw.setRegs(dfzRegs,'');
    end
    
    % Generating tables from FW object and remaining tables which are not managed through actual FW regs
    fw.generateTablesForFw(outFolder, 0, preserveThermalCalib, tableVersions);
    binTable = convertCalibDataToBinTable(struct('table', []), 'Algo_rtdOverAngX_CalibInfo');
    rtdOverXTableFileName = Calibration.aux.genTableBinFileName('Algo_rtdOverAngX_CalibInfo', tableVersions.algoRtdOverAngX);
    writeAllbytes(binTable, fullfile(outFolder, rtdOverXTableFileName));
    presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', tableVersions.dynamicRange);
    presetsPath = fileparts(outFolder);
    temp = dbstack;
    if (length(temp)>1) && strcmp(temp(2).name, 'GenInitCalibTables_Calc') % called by GenInitCalibTables_Calc
        calibData = struct('presetsPath', presetsPath);
    else % called directly
        calibData = struct;
    end
    binTable = convertCalibDataToBinTable(calibData, 'Dynamic_Range_Info_CalibInfo');
    writeAllBytes(binTable, fullfile(outFolder, presetsTableFileName));
    rgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Calibration_Info_CalibInfo', tableVersions.rgbCalib);
    writeAllBytes(zeros(1,112,'uint8'), fullfile(outFolder, rgbTableFileName));
    if ~preserveThermalCalib
        thermalRgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Thermal_Info_CalibInfo', tableVersions.rgbCalib);
        writeAllBytes(typecast(zeros(120,1,'single'),'uint8'), fullfile(outFolder, thermalRgbTableFileName));
    end
end
