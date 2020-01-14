function saveMemsTable( results, fullPathIn , fullPathOut )

fidIn = fopen(fullPathIn, 'rb');
bytesVec = uint8(fread(fidIn));
fclose(fidIn);

bytesVec(9:12)      = typecast(results.pzr(1).coef(1), 'uint8');
bytesVec(21:24)     = typecast(results.pzr(1).coef(2), 'uint8');
bytesVec(33:36)     = typecast(results.pzr(2).coef(1), 'uint8');
bytesVec(45:48)     = typecast(results.pzr(2).coef(2), 'uint8');
bytesVec(57:60)     = typecast(results.pzr(3).coef(1), 'uint8');
bytesVec(69:72)     = typecast(results.pzr(3).coef(2), 'uint8');
bytesVec(97:100)    = typecast(results.pzr(1).coef(3), 'uint8');
bytesVec(101:104)   = typecast(results.pzr(2).coef(3), 'uint8');
bytesVec(105:108)   = typecast(results.pzr(3).coef(3), 'uint8');
bytesVec(109)       = typecast(results.ctKillThr(1), 'uint8'); % cold
bytesVec(110)       = typecast(results.ctKillThr(2), 'uint8'); % hot
bytesVec(111:112)   = zeros(1,2,'uint8'); % reserved

fidOut = fopen(fullPathOut, 'wb');
fwrite(fidOut, bytesVec);
fclose(fidOut);

end












