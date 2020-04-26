function calibData = convertBinTableToCalibData(binTable, tableName, plotFlag)
% convertBinTableToCalibData:
%   Algo tables parser.

assert(isa(binTable, 'uint8'), 'Binary table at input must be of class uint8');
binTable = vec(binTable);
if ~exist('plotFlag', 'var')
    plotFlag = false;
end

switch tableName
    case 'Algo_AutoCalibration'
        calibData.timestamp = typecast(binTable(1:8), 'uint64');
        calibData.acVersion = single(binTable(9))+single(binTable(10))/100;
        calibData.flags = binTable(11:16);
        calibData.hFactor = typecast(binTable(17:20), 'single');
        calibData.vFactor = typecast(binTable(21:24), 'single');
        calibData.hOffset = typecast(binTable(25:28), 'single');
        calibData.vOffset = typecast(binTable(29:32), 'single');
        calibData.rtdOffset = typecast(binTable(33:36), 'single');
        calibData.reserved = binTable(37:48);
        
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
        if plotFlag
            figure
            subplot(2,3,[1,4])
            plot(rtdTable, '.-')
            grid on, xlabel('#bin'), ylabel('table [mm]'), title('RTD correction')
            subplot(2,3,2)
            plot(dsmTable(:,1), '.-')
            grid on, xlabel('#bin'), ylabel('table [1/deg]'), title('X scale')
            subplot(2,3,3)
            plot(dsmTable(:,3), '.-')
            grid on, xlabel('#bin'), ylabel('table [deg]'), title('X offset')
            subplot(2,3,5)
            plot(dsmTable(:,2), '.-')
            grid on, xlabel('#bin'), ylabel('table [1/deg]'), title('Y scale')
            subplot(2,3,6)
            plot(dsmTable(:,4), '.-')
            grid on, xlabel('#bin'), ylabel('table [deg]'), title('Y offset')
        end
        
    case 'Algo_Thermal_Loop_Extra_CalibInfo'
        tableUint16 = typecast(binTable, 'uint16');
        calibData.tmptrOffsetValuesShort = single(typecast(tableUint16, 'int16')) / 2^8;
        
    case 'AutoCalibration_Depth_DB'
        numOfEntries = double(typecast(binTable(1:2), 'int16'));
        entrySize = double(typecast(binTable(3:4), 'uint16'));
        calibData.activeIndex = double(typecast(binTable(5:6), 'int16'));
        calibData.reserved = binTable(7:16);
        for iEntry = 1:numOfEntries
            binEntry = binTable(16+(iEntry-1)*entrySize+(1:entrySize));
            calibData.entries(iEntry).timestamp = typecast(binEntry(1:8), 'uint64');
            calibData.entries(iEntry).acVersion = single(binEntry(9))+single(binEntry(10))/100;
            calibData.entries(iEntry).flags = binEntry(11:16);
            calibData.entries(iEntry).hFactor = typecast(binEntry(17:20), 'single');
            calibData.entries(iEntry).vFactor = typecast(binEntry(21:24), 'single');
            calibData.entries(iEntry).hOffset = typecast(binEntry(25:28), 'single');
            calibData.entries(iEntry).vOffset = typecast(binEntry(29:32), 'single');
            calibData.entries(iEntry).rtdOffset = typecast(binEntry(33:36), 'single');
            calibData.entries(iEntry).reserved = binEntry(37:48);
        end
        
    case 'AutoCalibration_RGB_DB'
        numOfEntries = double(typecast(binTable(1:2), 'int16'));
        entrySize = double(typecast(binTable(3:4), 'uint16'));
        calibData.activeIndex = double(typecast(binTable(5:6), 'int16'));
        calibData.reserved = binTable(7:16);
        for iEntry = 1:numOfEntries
            binEntry = binTable(16+(iEntry-1)*entrySize+(1:entrySize));
            calibData.entries(iEntry).timestamp = typecast(binEntry(1:8), 'uint64');
            calibData.entries(iEntry).acVersion = single(binEntry(9))+single(binEntry(10))/100;
            calibData.entries(iEntry).flags = binEntry(11:16);
            calibData.entries(iEntry).Fx = typecast(binEntry(17:20), 'single');
            calibData.entries(iEntry).Fy = typecast(binEntry(21:24), 'single');
            calibData.entries(iEntry).Px = typecast(binEntry(25:28), 'single');
            calibData.entries(iEntry).Py = typecast(binEntry(29:32), 'single');
            calibData.entries(iEntry).Rx = typecast(binEntry(33:36), 'single');
            calibData.entries(iEntry).Ry = typecast(binEntry(37:40), 'single');
            calibData.entries(iEntry).Rz = typecast(binEntry(41:44), 'single');
            calibData.entries(iEntry).Tx = typecast(binEntry(45:48), 'single');
            calibData.entries(iEntry).Ty = typecast(binEntry(49:52), 'single');
            calibData.entries(iEntry).Tz = typecast(binEntry(53:56), 'single');
            calibData.entries(iEntry).reserved = binEntry(57:64);
        end
        
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
        calibData.extrinsics.t = vec(typecast(binTable(93:104), 'single'));
        calibData.rgbCalTemperature = typecast(binTable(105:108), 'single');

    case 'RGB_Thermal_Info_CalibInfo'
        tableWithMetaData = typecast(binTable, 'single');
        calibData.minTemp = tableWithMetaData(1);
        calibData.maxTemp = tableWithMetaData(2);
        calibData.nBins = 29;
        if (length(tableWithMetaData(5:end)) == 4*calibData.nBins) % new format
            calibData.referenceTemp = tableWithMetaData(3);
            calibData.isValid = tableWithMetaData(4);
            calibData.thermalTable = reshape(tableWithMetaData(5:end), [], calibData.nBins)';
        else % old format
            calibData.referenceTemp = calibData.maxTemp;
            calibData.isValid = 1;
            calibData.thermalTable = reshape(tableWithMetaData(4:end), [], calibData.nBins)';
        end
        
    otherwise
        error('Unknown table name')
end
