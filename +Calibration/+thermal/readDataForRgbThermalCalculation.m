function [rgbData] = readDataForRgbThermalCalculation(hw)
%TODO: replace with a general function for reading EEPROM off unit
[rgbData] = getRgbThermalData(hw);
[rgbData.rgbCalTemp] = getRgbCalibTemp(hw);
end

function [rgbCalTemp] = getRgbCalibTemp(hw)
s = hw.cmd('READ_TABLE 10 0');
newStr = strsplit(s,'=> ');
newStr = strsplit(newStr{9},' ');
rgbCalTemp = double(hex2single([newStr{12} newStr{11} newStr{10} newStr{9}]));
end

function [rgbThermalData] = getRgbThermalData(hw)
[~,binData] = hw.cmd('READ_TABLE 17 0');
rgbThermalData = Calibration.tables.convertBinTableToCalibData(binData, 'RGB_Thermal_Info_CalibInfo');
end