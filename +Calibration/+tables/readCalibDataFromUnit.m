function [calibDataEeprom, calibDataFlash] = readCalibDataFromUnit(hw, tableName)
% readCalibDataFromUnit
%   Retrieves calibration data of all algo tables from unit's EEPROM and FLASH.
%   This version is compatible with TOC 109.

%                    Table Name                                     Table Id   Table Size [bytes]
eepromTablesInfo = {'Algo_Calibration_Info_CalibInfo',                 '13',   '200';...
                    'Algo_rtdOverAngX_CalibInfo',                      '15',   '80';... % max size 100
                    'Algo_Thermal_Loop_CalibInfo',                     'D',    '1F0';... % max size 200
                    'Algo_Thermal_Loop_Extra_CalibInfo',               '16',   '70';... % max size 100
                    'CBUF_Calibration_Info_CalibInfo',                 '14',   '200';...
                    'DEST_txPWRpd_Info_CalibInfo',                     '29',   '11C';... % max size 200
                    'DIGG_Gamma_Info_CalibInfo',                       '30',   'D4';... % max size 200
                    'DIGG_Undist_Info_1_CalibInfo',                    '40',   '1000';...
                    'DIGG_Undist_Info_2_CalibInfo',                    '41',   '1000';...
                    'Dynamic_Range_Info_CalibInfo',                    'F',    '100';...
                    %'FRMW_tmpTrans_Info',                              'XXX',  'C30';... %TODO: complete
                    'MEMS_Electro_Optics_Calibration_Info_CalibInfo',  '4',    '80';...
                    'RGB_Calibration_Info_CalibInfo',                  '10',   '80';...
                    'RGB_Thermal_Info_CalibInfo',                      '17',   '1F0'}; % max size 200
%                   Table Name               Table Id   Table Size [bytes]                
flashTablesInfo = {'Algo_AutoCalibration',      '240',  '40';...
                   'AutoCalibration_Depth_DB',  '241',  '400';... % max size 1000
                   'AutoCalibration_RGB_DB',    '242',  '400'}; % max size 1000
         
if exist('tableName', 'var')
    eepromTableInd = find(strcmp(eepromTablesInfo(:,1), tableName));
    flashTableInd = find(strcmp(flashTablesInfo(:,1), tableName));
    if isempty(eepromTableInd) && isempty(flashTableInd)
        error('tableName does not match any familiar table name.')
    else
        eepromTablesInfo = eepromTablesInfo(eepromTableInd,:);
        flashTablesInfo = flashTablesInfo(flashTableInd,:);
    end
end

calibDataEeprom = repmat(struct('tableName', '', 'tableData', []), [1,0]);
calibDataFlash = repmat(struct('tableName', '', 'tableData', []), [1,0]);

headerSize = 16; % 0x10
for iTable = 1:size(eepromTablesInfo, 1)
    tableIdEeprom = eepromTablesInfo{iTable,2};
    isPayload0 = strcmp(tableIdEeprom, '4');
    bytesToSkip = headerSize*(1-isPayload0);
    tableSize = hex2dec(eepromTablesInfo{iTable,3})-headerSize;
    calibDataEeprom(iTable).tableName = eepromTablesInfo{iTable,1};
    [~, binData] = hw.cmd(sprintf('ReadFullTable %s', tableIdEeprom));
    binData = binData(bytesToSkip + (1:tableSize));
    calibDataEeprom(iTable).tableData = Calibration.tables.convertBinTableToCalibData(binData, calibDataEeprom(iTable).tableName);
    if ~isPayload0 % table exists also in FLASH
        tableIdFlash = dec2hex(hex2dec(tableIdEeprom) + hex2dec('300'));
        calibDataFlash(iTable).tableName = eepromTablesInfo{iTable,1};
        [~, binData] = hw.cmd(sprintf('ReadFullTable %s', tableIdFlash));
        binData = binData(bytesToSkip + (1:tableSize));
        calibDataFlash(iTable).tableData = Calibration.tables.convertBinTableToCalibData(binData, calibDataFlash(iTable).tableName);
    end
end
nFlashTables = length(calibDataFlash);
for iTable = 1:size(flashTablesInfo, 1)
    tableIdFlash = flashTablesInfo{iTable,2};
    bytesToSkip = headerSize;
    tableSize = hex2dec(flashTablesInfo{iTable,3})-headerSize;
    calibDataFlash(nFlashTables+iTable).tableName = flashTablesInfo{iTable,1};
    try
        [~, binData] = hw.cmd(sprintf('READ_TABLE %s 0', tableIdFlash));
        tableSize = min(tableSize, length(binData)-bytesToSkip);
        binData = binData(bytesToSkip + (1:tableSize));
        calibDataFlash(nFlashTables+iTable).tableData = Calibration.tables.convertBinTableToCalibData(binData, calibDataFlash(nFlashTables+iTable).tableName);
    catch
        warning('Unable to retrieve table %s (please verify that FW supports AC)', calibDataFlash(nFlashTables+iTable).tableName);
        calibDataFlash(nFlashTables+iTable).tableData = [];
    end
end

