function [rgbData] = readDataForRgbThermalCalculation(hw,calibParams)
[rgbData] = getRgbThermalData(hw,calibParams);
[rgbData.rgbCalTemp] = getRgbCalibTemp(hw);
end

function [rgbCalTemp] = getRgbCalibTemp(hw)
s = hw.cmd('READ_TABLE 10 0');
newStr = strsplit(s,'=> ');
newStr = strsplit(newStr{9},' ');
rgbCalTemp = double(hex2single([newStr{12} newStr{11} newStr{10} newStr{9}]));
end

function [rgbThermalData] = getRgbThermalData(hw,calibParams)
[~,binData] = hw.cmd('READ_TABLE 17 0');
vals = typecast(binData(17:end),'single');
rgbThermalData.minTemp = vals(1);
rgbThermalData.maxTemp = vals(2);
rgbThermalData.referenceTemp = vals(3);
if isfield(calibParams.gnrl,'rgb') && isfield(calibParams.gnrl.rgb,'nBinsThermal')
    nBins = calibParams.gnrl.rgb.nBinsThermal;
else
    nBins = 29;
end
rgbThermalData.thermalTable = reshape(vals(4:end),[],nBins)';
end