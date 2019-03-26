function [] = writeAlgoThermalBin(obj,fname)

EXTLdsmXscale = obj.getAddrData('EXTLdsmXscale');
EXTLdsmYscale = obj.getAddrData('EXTLdsmYscale');
EXTLdsmXoffset = obj.getAddrData('EXTLdsmXoffset');
EXTLdsmYoffset = obj.getAddrData('EXTLdsmYoffset');
DESTtmptrOffset = obj.getAddrData('DESTtmptrOffset');

table = typecast([EXTLdsmXscale{2},EXTLdsmYscale{2},EXTLdsmXoffset{2},EXTLdsmYoffset{2},DESTtmptrOffset{2}],'single');
table = repmat(table,48,1);
table = int16(table*2^8);


table = reshape(table',[],1);
fileID = fopen(fname,'w');
fwrite(fileID,table','int16');
fclose(fileID);


end

