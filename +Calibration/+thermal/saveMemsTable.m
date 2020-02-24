function saveMemsTable( results, fullPathIn , fullPathOut )

fidIn = fopen(fullPathIn, 'rb');
bytesVec = uint8(fread(fidIn));
fclose(fidIn);

% HUM estimation model (R in KOhm): humEstCoef(1)*R^2 + humEstCoef(2)*R + humEstCoef(3)
% VSense estimation model (R in KOhm): vsenseEstCoef(1)*R^2 + vsenseEstCoef(2)*R + vsenseEstCoef(3)
bytesVec(9:12)      = typecast(results.pzr(1).humEstCoef(1), 'uint8');
bytesVec(21:24)     = typecast(results.pzr(1).humEstCoef(2), 'uint8');
bytesVec(33:36)     = typecast(results.pzr(2).humEstCoef(1), 'uint8');
bytesVec(45:48)     = typecast(results.pzr(2).humEstCoef(2), 'uint8');
bytesVec(57:60)     = typecast(results.pzr(3).humEstCoef(1), 'uint8');
bytesVec(69:72)     = typecast(results.pzr(3).humEstCoef(2), 'uint8');

bytesVec(73:76)     = typecast(results.pzr(1).vsenseEstCoef(1), 'uint8');
bytesVec(77:80)     = typecast(results.pzr(1).vsenseEstCoef(2), 'uint8');
bytesVec(81:84)     = typecast(results.pzr(1).vsenseEstCoef(3), 'uint8');
bytesVec(85:88)     = typecast(results.pzr(3).vsenseEstCoef(1), 'uint8');
bytesVec(89:92)     = typecast(results.pzr(3).vsenseEstCoef(2), 'uint8');
bytesVec(93:96)     = typecast(results.pzr(3).vsenseEstCoef(3), 'uint8');

bytesVec(97:100)    = typecast(results.pzr(1).humEstCoef(3), 'uint8');
bytesVec(101:104)   = typecast(results.pzr(2).humEstCoef(3), 'uint8');
bytesVec(105:108)   = typecast(results.pzr(3).humEstCoef(3), 'uint8');

bytesVec(109)       = typecast(results.ctKillThr(1), 'uint8'); % cold
bytesVec(110)       = typecast(results.ctKillThr(2), 'uint8'); % hot
bytesVec(111:112)   = zeros(1,2,'uint8'); % reserved

fidOut = fopen(fullPathOut, 'wb');
fwrite(fidOut, bytesVec);
fclose(fidOut);

end












