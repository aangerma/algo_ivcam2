function binTable = convertCalibDataToBinTable(calibData, tableName)
% convertCalibDataToBinTable:
%   Complementary function to @Firmware\generateTablesForFw, handles all
%   algo tables that are not reflected onto ASIC regs, but serving FW loops
%   or post-processing.

switch tableName
    case 'Algo_AutoCalibration'
        acVerMajorMinor = [calibData.acVersion; 100*mod(calibData.acVersion,1)];
        correctionData = [calibData.hFactor; calibData.vFactor; calibData.hOffset; calibData.vOffset; calibData.rtdOffset];
        binTable = [typecast(uint64(calibData.timestamp), 'uint8')'; uint8(acVerMajorMinor); uint8(calibData.flags(:)); typecast(single(correctionData), 'uint8'); uint8(calibData.reserved(:))];
        
    case 'Algo_Calibration_Info_CalibInfo'
        % Implemented in @Firmware\generateTablesForFw based on regsDefinitions.frmw (TransferToFW=1)
        binTable = NaN;

    case 'Algo_rtdOverAngX_CalibInfo'
        nLines = typecast(uint32(numel(calibData.table)), 'single');
        tableSingle = [nLines; single(vec(calibData.table))];
        binTable = typecast(tableSingle, 'uint8');
        
    case 'Algo_Thermal_Loop_CalibInfo'
        dsmTableUint16 = uint16(calibData.table(:,1:4) * 2^8);
        rtdTableUint16 = typecast(int16(calibData.table(:,5) * 2^8), 'uint16');
        tableUint16 = [dsmTableUint16, rtdTableUint16];
        binTable = typecast(reshape(tableUint16', [], 1), 'uint8');

    case 'Algo_Thermal_Loop_Extra_CalibInfo'
        tableUint16 = typecast(int16(calibData.tmptrOffsetValuesShort * 2^8), 'uint16');
        binTable = typecast(vec(tableUint16), 'uint8');

    case 'AutoCalibration_Depth_DB'
        numOfEntries = int16(length(calibData.entries));
        entrySize = uint16(48);
        binTable = [typecast(numOfEntries, 'uint8')'; typecast(entrySize, 'uint8')'; typecast(int16(calibData.activeIndex), 'uint8')'; uint8(calibData.reserved(:))];
        for iEntry = 1:numOfEntries
            curEntry = calibData.entries(iEntry);
            acVerMajorMinor = [curEntry.acVersion; 100*mod(curEntry.acVersion,1)];
            correctionData = [curEntry.hFactor; curEntry.vFactor; curEntry.hOffset; curEntry.vOffset; curEntry.rtdOffset];
            binTable = [binTable; typecast(int64(curEntry.timestamp), 'uint8')'; uint8(acVerMajorMinor); uint8(curEntry.flags(:)); typecast(single(correctionData), 'uint8'); uint8(curEntry.reserved(:))];
        end
        
    case 'AutoCalibration_RGB_DB'
        numOfEntries = int16(length(calibData.entries));
        entrySize = uint16(64);
        binTable = [typecast(numOfEntries, 'uint8')'; typecast(entrySize, 'uint8')'; typecast(int16(calibData.activeIndex), 'uint8')'; uint8(calibData.reserved(:))];
        for iEntry = 1:numOfEntries
            curEntry = calibData.entries(iEntry);
            acVerMajorMinor = [curEntry.acVersion; 100*mod(curEntry.acVersion,1)];
            correctionData = [curEntry.Fx; curEntry.Fy; curEntry.Px; curEntry.Py; curEntry.Rx; curEntry.Ry; curEntry.Rz; curEntry.Tx; curEntry.Ty; curEntry.Tz];
            binTable = [binTable; typecast(int64(curEntry.timestamp), 'uint8')'; uint8(acVerMajorMinor); uint8(curEntry.flags(:)); typecast(single(correctionData), 'uint8'); uint8(curEntry.reserved(:))];
        end
        
    case 'CBUF_Calibration_Info_CalibInfo'
        % Implemented in @Firmware\generateTablesForFw based on regsDefinitions.frmw (TransferToFW=3)
        binTable = NaN;
        
    case 'DEST_txPWRpd_Info_CalibInfo'
        % Implemented in @Firmware\generateTablesForFw based on regsDefinitions.frmw (TransferToFW=6)
        binTable = NaN;
        
    case 'DIGG_Gamma_Info_CalibInfo'
        % Implemented in @Firmware\generateTablesForFw based on regsDefinitions.frmw (TransferToFW=4)
        binTable = NaN;
        
    case 'DIGG_Undist_Info_1_CalibInfo'
        % Implemented in @Firmware\writeLUTbin based on assignment in End_Calib_Calc_int
        binTable = NaN;
        
    case 'DIGG_Undist_Info_2_CalibInfo'
        % Implemented in @Firmware\writeLUTbin based on assignment in End_Calib_Calc_int
        binTable = NaN;
        
    case 'Dynamic_Range_Info_CalibInfo'
        if ~isfield(calibData, 'presetsPath')
            pathLR = '..\+presets\+defaultValues\longRangePreset.csv';
            pathSR = '..\+presets\+defaultValues\shortRangePreset.csv';
        else
            pathLR = fullfile(calibData.presetsPath, 'longRangePreset.csv');
            pathSR = fullfile(calibData.presetsPath, 'shortRangePreset.csv');
        end
        longRangePreset = readtable(pathLR);
        shortRangePreset = readtable(pathSR);
        % definitions
        tableSize = 120*2;
        resrevedLength = 33;
        s = Stream(zeros(1, tableSize, 'uint8'));
        for iParam = 1:size(longRangePreset, 1)
            type = longRangePreset.type{iParam};
            value = longRangePreset.value(iParam);
            s.setNext(value, type);
        end
        for iParam = 1:resrevedLength
            s.setNext(0, 'uint8');
        end
        for iParam = 1:size(shortRangePreset,1)
            type = shortRangePreset.type{iParam};
            value = shortRangePreset.value(iParam);
            s.setNext(value, type);
        end
        binTable = s.flush();

    case 'FRMW_tmpTrans_Info'
        % Implemented in @Firmware\writeLUTbin)
        binTable = NaN;

    case 'MEMS_Electro_Optics_Calibration_Info_CalibInfo'
        binTable = zeros(0, 1, 'uint8');
        for iPzr = 1:3
            pzrData = single([calibData.pzr(iPzr).psiDevAlpha; calibData.pzr(iPzr).s0; calibData.pzr(iPzr).humEstCoef(1); calibData.pzr(iPzr).vb0Nom; calibData.pzr(iPzr).ib0Nom; calibData.pzr(iPzr).humEstCoef(2)]);
            binTable = [binTable; typecast(pzrData, 'uint8')];
        end
        for iPzr = [1,3]
            pzrData = single(vec(calibData.pzr(iPzr).vsenseEstCoef));
            binTable = [binTable; typecast(pzrData, 'uint8')];
        end
        for iPzr = 1:3
            pzrData = single(calibData.pzr(iPzr).humEstCoef(3));
            binTable = [binTable; vec(typecast(pzrData, 'uint8'))];
        end
        tempDataUint8 = [typecast(int8(vec(calibData.ctKillThr)), 'uint8'); zeros(2,1,'uint8')];
        binTable = [binTable; tempDataUint8];
        
    case 'RGB_Calibration_Info_CalibInfo'
        [~, ~, versionBytes] = AlgoCameraCalibToolVersion;
        calibratorId = uint8(1);
        procId = uint8(0);
        timeStamp = vec(typecast(uint32(now), 'uint8'));
        imSize = typecast(uint16(vec(calibData.rgbImageSize)), 'uint8');
        metaDataUint8 = [vec(versionBytes(1:2)); calibratorId; procId; timeStamp; imSize; typecast(zeros(2,1,'uint16'), 'uint8')];
        intrinsicDataUint8 = typecast(single([calibData.color.Kn([1,5,7,8,4]); vec(calibData.color.d)]), 'uint8');
        extrinsicDataUint8 = typecast(single([vec(calibData.extrinsics.r'); vec(calibData.extrinsics.t)]), 'uint8');
        tempDataUint8 = typecast(single([calibData.rgbCalTemperature; 0]), 'uint8');
        binTable = [metaDataUint8; intrinsicDataUint8; extrinsicDataUint8; tempDataUint8];

    case 'RGB_Thermal_Info_CalibInfo'
        thermalTable = reshape(calibData.thermalTable', [], 1);
        tableWithMetaData = [calibData.minTemp; calibData.maxTemp; calibData.referenceTemp; calibData.isValid; thermalTable];
        binTable = typecast(single(tableWithMetaData), 'uint8');
        
    otherwise
        error('Unknown table name')
end
