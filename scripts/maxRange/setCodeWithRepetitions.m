function [  ] = setCodeWithRepetitions( hw,origLength,repeat)
%SETCODE26WITHREPETITIONS loads code 52 or 64 and do repetitions for each symbol.
% Trim the code at length 52.

% FRMWtxCode_000 h69966665
% FRMWtxCode_001 h000A6AA9
% GNRLcodeLength d52
assert(any(origLength == [64,52]));
baseLen = floor(origLength/repeat);
codeO = Codes.propCode(origLength,1)';
baseCode = codeO(1:baseLen);
repeatedCode = reshape((repmat(baseCode,repeat,1)),[],1)';
padding = ((-1).^(1:origLength-length(repeatedCode))+1)/2;
repeatedCode = [repeatedCode,padding];

txcode = zeros(1,64);
txcode(1:origLength) = repeatedCode;
txcode = binaryVectorToHex(fliplr(reshape(txcode',32,2)'));

txregs.FRMW.txCode = uint32([hex2dec(txcode{1}),hex2dec(txcode{2}),0,0]);
txregs.GNRL.codeLength = uint8(origLength);
txregs.FRMW.coarseSampleRate = uint8(2);

hw.setCode(txregs,0);
end

