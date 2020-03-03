function [calibDataEeprom, calibDataFlash] = readCalibDataFromUnit(hw, tableName)
% readCalibDataFromUnit
%   Retrieves calibration data of all algo tables from unit's EEPROM and FLASH.
%   This version is compatible with TOC 109.

tableInfo = {'Algo_Calibration_Info_CalibInfo',                 '13',   '200';...
             'Algo_rtdOverAngX_CalibInfo',                      '15',   '80';...
             'Algo_Thermal_Loop_CalibInfo',                     'D',    '1F0';...
             'Algo_Thermal_Loop_Extra_CalibInfo',               '16',   '70';...
             'CBUF_Calibration_Info_CalibInfo',                 '14',   '200';...
             'DEST_txPWRpd_Info_CalibInfo',                     '29',   '11C';...
             'DIGG_Gamma_Info_CalibInfo',                       '30',   'D4';...
             'DIGG_Undist_Info_1_CalibInfo',                    '40',   '1000';...
             'DIGG_Undist_Info_2_CalibInfo',                    '41',   '1000';...
             'Dynamic_Range_Info_CalibInfo',                    'F',    '100';...
             %'FRMW_tmpTrans_Info',                              'XXX',  'C30';... %TODO: complete
             'MEMS_Electro_Optics_Calibration_Info_CalibInfo',  '4',    '80';...
             'RGB_Calibration_Info_CalibInfo',                  '10',   '80';...
             'RGB_Thermal_Info_CalibInfo',                      '17',   '1E8'};

if exist('tableName', 'var')
    tableInd = find(strcmp(tableInfo(:,1), tableName));
    if isempty(tableInd)
        error('tableName does not match any familiar table name.')
    else
        tableInfo = tableInfo(tableInd,:);
    end
end

headerSize = 16;
for iTable = 1:size(tableInfo, 1)
    tableIdEeprom = tableInfo{iTable,2};
    isPayload0 = strcmp(tableIdEeprom, '4');
    if isPayload0
        bytesToSkip = 0;
    else
        bytesToSkip = headerSize;
    end
    tableSize = hex2dec(tableInfo{iTable,3})-headerSize;
    calibDataEeprom(iTable).tableName = tableInfo{iTable,1};
    [~, binData] = hw.cmd(sprintf('ReadFullTable %s', tableIdEeprom));
    binData = binData(bytesToSkip + (1:tableSize));
    calibDataEeprom(iTable).tableData = Calibration.tables.convertBinTableToCalibData(binData, calibDataEeprom(iTable).tableName);
    if ~isPayload0
        tableIdFlash = dec2hex(hex2dec(tableIdEeprom) + hex2dec('300'));
        calibDataFlash(iTable).tableName = tableInfo{iTable,1};
        [~, binData] = hw.cmd(sprintf('ReadFullTable %s', tableIdFlash));
        binData = binData(bytesToSkip + (1:tableSize));
        calibDataFlash(iTable).tableData = Calibration.tables.convertBinTableToCalibData(binData, calibDataFlash(iTable).tableName);
    end
end

