function [txCodeRegDec,txCodeRegHex,txCodeRegBin,codeLength] = genCodeReg(new_code_double,new_code_length)
codeSequence = binaryVectorToHex(fliplr(new_code_double));
txSequence = char(zeros(1,new_code_length));
txSequence(1,length(txSequence)- length(codeSequence)+1:end) = codeSequence;
txCodeRegDec = uint32([hex2dec(txSequence(end-7:end)),hex2dec(txSequence(end-15:end-8)),hex2dec(txSequence(end-23:end-16)),hex2dec(txSequence(1:end-24))]);
txCodeRegHex=dec2hex(txCodeRegDec);
codeLength = uint8(new_code_length);
txCodeRegBin=dec2bin(txCodeRegDec,32);
end

