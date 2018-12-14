function [  ] = setCodeWithRepetitions( hw,origLength,repeat)
%SETCODE26WITHREPETITIONS loads code 52 or 64 and do repetitions for each symbol.

% FRMWtxCode_000 h69966665
% FRMWtxCode_001 h000A6AA9
% GNRLcodeLength d52
% assert(any(origLength == [64,52]));
baseLen = (origLength);
if baseLen ~= 13
    codeO = Codes.propCode(origLength,1)';
else
    [~,~,codeO] = Codes.barker13;
    codeO = codeO' < 0;
end
baseCode = codeO(1:baseLen);
repeatedCode = reshape((repmat(baseCode,repeat,1)),[],1)';

txcode = zeros(1,128);
txcode(1:origLength*repeat) = repeatedCode;
txcode = binaryVectorToHex(fliplr(reshape(txcode',32,4)'));

txregs.FRMW.txCode = uint32([hex2dec(txcode{1}),hex2dec(txcode{2}),0,0]);
txregs.GNRL.codeLength = uint8(origLength*repeat);
txregs.FRMW.coarseSampleRate = uint8(2);

hw.setCode(txregs,0);
end

