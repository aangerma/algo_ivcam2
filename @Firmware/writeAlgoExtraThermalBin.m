function [] = writeAlgoExtraThermalBin(obj,fname)

shortPresetRtdTable = zeros(48,1,'uint16');

fileID = fopen(fname,'w');
fwrite(fileID,shortPresetRtdTable','uint16');
fclose(fileID);


end

