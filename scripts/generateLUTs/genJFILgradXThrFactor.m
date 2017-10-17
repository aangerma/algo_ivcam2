function lutOut = genJFILgradXThrFactor()
LUT = zeros([1 2^6], 'uint8');

LUT(1:16) = 31;
LUT(17:48) = (1:32) + 31;
LUT(49:64) = 63;
LUT = uint8(LUT);
% figure; plot(LUT);

% f1 = fopen('../JFILgrad1ThrFactor.lut', 'wt');
% f2 = fopen('../JFILgrad2ThrFactor.lut', 'wt');
% 
% fprintf(f1,'%02x\n', LUT);
% fprintf(f2,'%02x\n', LUT);
% 
% fclose(f1);
% fclose(f2);

lutOut1.lut = LUT;
lutOut1.name = 'JFILgrad1ThrFactor';
lutOut2.lut = LUT;
lutOut2.name = 'JFILgrad2ThrFactor';
lutOut = [lutOut1 lutOut2];
end