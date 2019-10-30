function [fnCalib,fnUndsitLut] = defineFileNamesAndCreateResultsDir(internalFolder, configurationFolder)
    mkdirSafe(internalFolder);
    fnCalib     = fullfile(internalFolder,'calib.csv');
    fnUndsitLut = fullfile(internalFolder,'FRMWundistModel.bin32');
    initFldr = fullfile(fileparts(mfilename('fullpath')), '../', configurationFolder);
    initPresetsFolder = fullfile(fileparts(mfilename('fullpath')), '../','+presets','+defaultValues');
    eepromStructureFn = fullfile(fileparts(mfilename('fullpath')), '../','eepromStructure');
    copyfile(fullfile(initFldr,'*.csv'),  internalFolder);
    copyfile(fullfile(initPresetsFolder,'*.csv'),  internalFolder);
    copyfile(fullfile(ivcam2root ,'+Pipe' ,'tables','*.frmw'), internalFolder);
    copyfile(fullfile(eepromStructureFn,'*.csv'),  internalFolder);
    copyfile(fullfile(eepromStructureFn,'*.mat'),  internalFolder);
end