function [  ] = writeRtdOverAngXTable(obj, fname ,tableValues)
tableValues = [typecast(uint32(numel(tableValues)),'single');tableValues(:)]; % Add the number of lines as a header
fileID = fopen(fname,'w');
fwrite(fileID,tableValues','single');
fclose(fileID);

end

