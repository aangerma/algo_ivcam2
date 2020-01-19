function rgbThermalData = convertRgbThermalBytesToData(rgbThermalBinData,nBinsRgb)
    vals = typecast(rgbThermalBinData(17:end),'single');
    rgbThermalData.minTemp = vals(1);
    rgbThermalData.maxTemp = vals(2);
    
    if numel(vals(5:end))/4 ~= nBinsRgb %Backwards compatibility
        rgbThermalData.referenceTemp = rgbThermalData.maxTemp;
        rgbThermalData.isValid = 1;
        rgbThermalData.thermalTable = reshape(vals(3:end),[],nBinsRgb)';
    else
        rgbThermalData.referenceTemp = vals(3);
        rgbThermalData.isValid = vals(4);
        rgbThermalData.thermalTable = reshape(vals(5:end),[],nBinsRgb)';
    end
end

