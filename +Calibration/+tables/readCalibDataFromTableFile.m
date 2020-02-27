function calibData = readCalibDataFromTableFile(binFileName)
% readCalibDataFromTableFile
%   Retrieves calibration data of a single algo table from table BIN file.

fid = fopen(binFileName, 'rb');
binData = fread(fid, Inf, '*uint8');
fclose(fid);

ind = strfind(binFileName, '_Ver');
if ~isempty(ind)
    tableName = binFileName(1:ind-1);
else
    ind = strfind(binFileName, '.bin');
    if ~isempty(ind)
        tableName = binFileName(1:ind-1);
    else
        error('Input file must be a BIN file')
    end
end

calibData = Calibration.tables.convertBinTableToCalibData(binData, tableName);
