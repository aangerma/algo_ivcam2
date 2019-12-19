function rgbThermalData = convertRgbThermalBytesToData(rgbThermalBinData,nBinsRgb)
    vals = typecast(rgbThermalBinData(17:end),'single');
    rgbThermalData.minTemp = vals(1);
    rgbThermalData.maxTemp = vals(2);
    rgbThermalData.referenceTemp = vals(3);
    rgbThermalData.isVlid = vals(4);
    rgbThermalData.thermalTable = reshape(vals(5:end),[],nBinsRgb)';
end

