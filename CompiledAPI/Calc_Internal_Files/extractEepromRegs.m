function eepromRegs = extractEepromRegs(eepromBin, calib_dir)

initFolder      = calib_dir;
fw              = Pipe.loadFirmware(initFolder, 'tablesFolder', initFolder);
eepromStructure = load(fullfile(calib_dir, 'eepromStructure.mat'));
eepromStructure = eepromStructure.updatedEpromTable;
eepromBin       = uint8(eepromBin);
eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end), eepromStructure);

end