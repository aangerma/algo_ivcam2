function [  ] = saveRgbThermalTable( table , fname )
% Table columns holds the minTemp	referenceTemp	scaleCosParams transXparam transYparam
% scaleSineParams of the non-reflective similarity transformation for each
% temperature range to reference temperature

table = reshape(table',[],1);
fileID = fopen(fname,'w');
fwrite(fileID,table','single');
fclose(fileID);

end