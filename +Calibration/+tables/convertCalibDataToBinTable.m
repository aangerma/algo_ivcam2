function binTable = convertCalibDataToBinTable(calibData, tableName)
% convertCalibDataToBinTable:
%   Complementary function to @Firmware\generateTablesForFw, handles all
%   algo tables that are not reflected onto ASIC regs, but serving FW loops
%   or post-processing.

switch tableName
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
        %TODO: take from writeDynamicRangeTable
        binTable = NaN;
        
    case 'FRMW_tmpTrans_Info'
        % Implemented in @Firmware\generateTablesForFw based on regsDefinitions.frmw (TransferToFW=0)
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
        tempDataUint8 = [uint8(vec(calibData.ctKillThr)); zeros(2,1,'uint8')];
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
