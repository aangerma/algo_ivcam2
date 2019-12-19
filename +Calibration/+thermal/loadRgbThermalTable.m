function [rgbThermalData] = loadRgbThermalTable(binPath,nBins)
fileID = fopen(binPath,'r');
A = fread(fileID,'single');
fclose(fileID);
rgbThermalData.minTemp = A(1);
rgbThermalData.maxTemp = A(2);
rgbThermalData.referenceTemp = A(3);
rgbThermalData.isValid = A(4);
if ~exist('nBins','var')
    nBins = 29;
end
thermalTable = reshape(A(5:end),[],nBins)';
rgbThermalData.thermalTable = thermalTable;
end

