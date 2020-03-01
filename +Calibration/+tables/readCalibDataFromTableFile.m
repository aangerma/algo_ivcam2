function calibData = readCalibDataFromTableFile(binFileName)
% readCalibDataFromTableFile
%   Retrieves calibration data of a single algo table from table BIN file.

fid = fopen(binFileName, 'rb');
binTable = fread(fid, Inf, '*uint8');
fclose(fid);

[~, binFileName, ext] = fileparts(binFileName);
assert(strcmp(ext, '.bin'), 'Input file must be a BIN file')
ind = strfind(binFileName, '_Ver');
if ~isempty(ind)
    tableName = binFileName(1:ind-1);
end

calibData = Calibration.tables.convertBinTableToCalibData(binTable, tableName);
