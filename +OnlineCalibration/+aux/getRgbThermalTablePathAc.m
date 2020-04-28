function [rgbThermalBinPath] = getRgbThermalTablePathAc(sceneDir)
ix = strfind(sceneDir,'F');
unitSN =  sceneDir(ix:ix+7);
basePath = 'X:\IVCAM2_calibration _testing\unitCalibrationData';
dirData = dir(fullfile(basePath,unitSN));
names = [dirData.name];
ix = strfind(names,'ACC');
accName = names(ix:ix+3);
dirData = dir(fullfile(basePath,unitSN,accName,'Matlab\calibOutputFiles'));
names = [dirData.name];
ix = strfind(names,'RGB_Thermal_Info_CalibInfo_Ver_');
tableName = names(ix:ix+39);
rgbThermalBinPath = fullfile(basePath,unitSN,accName,'Matlab\calibOutputFiles',tableName);
end

