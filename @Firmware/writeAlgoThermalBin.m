function [] = writeAlgoThermalBin(obj,fname)

EXTLdsmXscale = obj.getAddrData('EXTLdsmXscale');
EXTLdsmYscale = obj.getAddrData('EXTLdsmYscale');
EXTLdsmXoffset = obj.getAddrData('EXTLdsmXoffset');
EXTLdsmYoffset = obj.getAddrData('EXTLdsmYoffset');
DESTtmptrOffset = obj.getAddrData('DESTtmptrOffset');

table = typecast([EXTLdsmXscale{2},EXTLdsmYscale{2},EXTLdsmXoffset{2},EXTLdsmYoffset{2},DESTtmptrOffset{2}],'single');
% table = repmat(table,48,1);
dsmTable = table(:,1:4);
rtdTable = table(:,5);

dsmTable = repmat(dsmTable,48,1);
dsmTable = uint16(dsmTable*2^8);

rtdTable = repmat(rtdTable,48,1);
rtdTable = typecast(int16(rtdTable*2^8),'uint16');

table = [dsmTable,rtdTable];

table = reshape(table',[],1);
fileID = fopen(fname,'w');
fwrite(fileID,table','uint16');
fclose(fileID);


end

