function [  ] = saveThermalTable( table , fname )
% Table columns holds the dsmXscale	dsmYscale	dsmXoffset	dsmYoffset
% DESTtmptrOffset values. The row indicates the temperature, starting with
% 25 degrees and goes up to 70.

table = reshape(table',[],1);
fileID = fopen(fname,'w');
fwrite(fileID,table','uint16');
fclose(fileID);

end