function [  ] = saveExtraThermalTable( rtdForVectorShort , fname )

table = rtdForVectorShort(:);
fileID = fopen(fname,'w');
fwrite(fileID,table','uint16');
fclose(fileID);

end