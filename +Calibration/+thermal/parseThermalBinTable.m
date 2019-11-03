function [thermalTable] = parseThermalBinTable(binFilePath)
f = fopen(binFilePath,'rb');
buffer = fread(f,Inf,'uint16');
table = reshape(buffer,5,48);
table = table';
dsmCols = single(table(:,1:4))./2^8;
rtdCol = single(typecast(uint16(table(:,5)), 'int16'))./2^8;
thermalTable = [dsmCols,rtdCol];
fclose(f);
end

