function [ table ] = loadThermalTable( fname )
fileID = fopen(fname,'r');
data = fread(fileID);
fclose(fileID);
table = reshape(data,5,[])';
end

