function rgbThermalData = convertRgbThermalBytesToData(rgbThermalBinData,nBinsRgb)
    vals = typecast(rgbThermalBinData(17:end),'single');
    rgbThermalData.minTemp = vals(1);
    rgbThermalData.maxTemp = vals(2);
%     rgbThermalData.referenceTemp = vals(3); %For future use when the refernce will be saved in ATC as well
    rgbThermalData.thermalTable = reshape(vals(3:end),[],nBinsRgb)';
end

