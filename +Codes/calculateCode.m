function [new_code_double,txCodeRegDec,txCodeRegHex,txCodeRegBin,codeLength] = calculateCode(orig_code_length,new_code_length)
orig_code = Codes.propCode(orig_code_length,1);
new_code_double = repelem(orig_code,new_code_length/orig_code_length)';
[txCodeRegDec,txCodeRegHex,txCodeRegBin,codeLength] = Codes.genCodeReg(new_code_double,new_code_length); 
new_code_double=new_code_double'; 

end

