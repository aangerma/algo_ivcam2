function generateAndBurnTable(hw,table,calibParams,runParams)
% Creates a binary table as requested

tableShifted = int16(table * 2^8); % FW expected format
tableName = fullfile(runParams.outputFolder,calibParams.fwTable.name);
saveThermalTable( tableShifted , tableName );
hw.cmd(['WrFullTable' tableName]);

end
function [  ] = saveThermalTable( table , fname )
% Table columns holds the dsmXscale	dsmYscale	dsmXoffset	dsmYoffset
% DESTtmptrOffset values. The row indicates the temperature, starting with
% 25 degrees and goes up to 70.

table = single(table);
table = reshape(table',[],1);
fileID = fopen(fname,'w');
fwrite(fileID,table','int16');
fclose(fileID);

end