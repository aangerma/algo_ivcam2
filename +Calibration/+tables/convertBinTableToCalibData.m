function calibData = convertBinTableToCalibData(binTable, tableName)
% convertBinTableToCalibData:
%   Algo tables parser.

assert(isa(binTable, 'uint8'), 'Binary table at input must be of class uint8');
binTable = vec(binTable);

switch tableName
    case 'Algo_Calibration_Info_CalibInfo'
        fw = Firmware;
        calibData = fw.readAlgoEpromData(binTable); % calibData = regs

    case 'Algo_rtdOverAngX_CalibInfo'
        tableSingle = typecast(binTable, 'single');
        nLines = typecast(tableSingle(1), 'uint32');
        calibData.table = tableSingle(1+(1:nLines));
        
    case 'Algo_Thermal_Loop_CalibInfo'
        tableUint16 = reshape(typecast(binTable, 'uint16'), 5, 48)';
        dsmTable = single(tableUint16(:,1:4)) / 2^8;
        rtdTable = single(typecast(tableUint16(:,5), 'int16')) / 2^8;
        calibData.table = [dsmTable, rtdTable];
        
    case 'Algo_Thermal_Loop_Extra_CalibInfo'
        tableUint16 = typecast(binTable, 'uint16');
        calibData.tmptrOffsetValuesShort = single(typecast(tableUint16, 'int16')) / 2^8;
        
    case 'CBUF_Calibration_Info_CalibInfo'
        calibData = binTable;
        
    case 'DEST_txPWRpd_Info_CalibInfo'
        calibData = binTable;
        
    case 'DIGG_Gamma_Info_CalibInfo'
        calibData = binTable;
        
    case 'DIGG_Undist_Info_1_CalibInfo'
        calibData = binTable;
        
    case 'DIGG_Undist_Info_2_CalibInfo'
        calibData = binTable;      
        
    case 'Dynamic_Range_Info_CalibInfo'
        %TODO: implement
        calibData = binTable;  
        
    case 'FRMW_tmpTrans_Info'
        calibData = binTable;

    case 'MEMS_Electro_Optics_Calibration_Info_CalibInfo'
        if (length(binTable)<112)
            binTable = [binTable; zeros(112-length(binTable),1,'uint8')];
        end
        for iPzr = 1:3
            calibData.pzr(iPzr).psiDevAlpha = typecast(binTable((1:4)+(iPzr-1)*24), 'single');
            calibData.pzr(iPzr).s0 = typecast(binTable((5:8)+(iPzr-1)*24), 'single');
            calibData.pzr(iPzr).vb0Nom = typecast(binTable((13:16)+(iPzr-1)*24), 'single');
            calibData.pzr(iPzr).ib0Nom = typecast(binTable((17:20)+(iPzr-1)*24), 'single');
            calibData.pzr(iPzr).humEstCoef = typecast(binTable([(9:12)+(iPzr-1)*24, (21:24)+(iPzr-1)*24, (97:100)+(iPzr-1)*4]), 'single');
        end
        for iPzr = [1,3]
            calibData.pzr(iPzr).vsenseEstCoef = typecast(binTable((73:84) + double(iPzr==3)*12), 'single');
        end
        calibData.ctKillThr = typecast(binTable(109:110), 'int8');
        
    case 'RGB_Calibration_Info_CalibInfo'
        metaDataUint8 = binTable(1:16);
        calibData.rgbImageSize = reshape(typecast(metaDataUint8(9:12), 'uint16'), 1, []);
        calibData.color.Kn = zeros(3, 3, 'single');
        calibData.color.Kn(3,3) = 1;
        calibData.color.Kn([1,5,7,8,4]) = typecast(binTable(17:36), 'single');
        calibData.color.d = typecast(binTable(37:56), 'single');
        calibData.extrinsics.r = reshape(typecast(binTable(57:92), 'single'), [3,3])';
        calibData.extrinsics.t = typecast(binTable(93:104), 'single');
        calibData.rgbCalTemperature = typecast(binTable(105:108), 'single');

    case 'RGB_Thermal_Info_CalibInfo'
        tableWithMetaData = typecast(binTable, 'single');
        calibData.minTemp = tableWithMetaData(1);
        calibData.maxTemp = tableWithMetaData(2);
        if (length(tableWithMetaData(5:end)) == 4*29) % new format
            calibData.referenceTemp = tableWithMetaData(3);
            calibData.isValid = tableWithMetaData(4);
            calibData.thermalTable = reshape(tableWithMetaData(5:end), [], 29)';
        else % old format
            calibData.referenceTemp = calibData.maxTemp;
            calibData.isValid = 1;
            calibData.thermalTable = reshape(tableWithMetaData(3:end), [], 29)';
        end
        
    otherwise
        error('Unknown table name')
end
