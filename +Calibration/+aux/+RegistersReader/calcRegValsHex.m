function [val_hex] = calcRegValsHex(hw, startAddress, endAddress, protocol, bitRange, val_dec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes the decimal value in val_dec and calculates the register value 
% in hexadecimal (val_hex) with changing only the bits in bitRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
readVal =  Calibration.aux.RegistersReader.getRegVal(hw, startAddress, endAddress, protocol);
binVal = fliplr(hexToBinaryVector(readVal,32));
indices = bitRange(1):bitRange(2);
newBinVal = fliplr(dec2bin(val_dec,bitRange(2)-bitRange(1)+1));
newBinValLogic = logical(newBinVal(:)'-'0');
binVal(indices+1) = newBinValLogic;
val_hex = binaryVectorToHex(fliplr(binVal));
end