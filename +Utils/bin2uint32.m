function [ uint32Code, codeLength ] = bin2uint32( binCode )
%specific for our codes with max length of 128!
%this is why it's under the +Codes dir. do not move.

codeLength = uint8(length(binCode));

k = false(1,128);
k(1:length(binCode))= binCode;
uint32Code = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');
end

