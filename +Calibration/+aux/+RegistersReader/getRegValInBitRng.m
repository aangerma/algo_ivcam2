function [val_hex_bit,val_dec_bit] = getRegValInBitRng(hw, startAddress, endAddress, protocol, bitRange)
if strcmp(protocol, 'APD')
    [val_hex_bit, val_dec_bit] = getRegVal(hw, startAddress, endAddress, protocol);
    return;
end
val_hex =  Calibration.aux.RegistersReader.getRegVal(hw, startAddress, endAddress, protocol); %Get the value of all teh bits in current address
binVal = fliplr(hexToBinaryVector(val_hex,32)); %Flip in order to treat it as a Matlab array
indices = bitRange(1):bitRange(2);
val_hex_bit = binaryVectorToHex(fliplr(binVal(indices+1)));
val_dec_bit = hex2dec(val_hex_bit); 
end

