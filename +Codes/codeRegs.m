function [ txregs ] = codeRegs( len,decRatio )
%CODEREGS returns a regs struct with the relevant code params. Output can
%used with hw.setCode() function. It is assumed rx over tx rate is 8.
% Supported options:
% 1. Code 64 coarse dec 4.
% 2. Code 64 coarse dec 8.
% 3. Code 62 coarse dec 4.
% 4. Code 62 coarse dec 8.
% 5. Code 52 coarse dec 4.
% 6. Code 52 coarse dec 8.

assert(any(len==[52,62,64]),'len should be one of [52,62,64]')
assert(any(decRatio==[2,4,8]),'len should be one of [52,62,64]')
if len == 52
    txregs.FRMW.txCode = uint32([hex2dec('69966665'),hex2dec('000A6AA9'),0,0]);
elseif len == 62
    txregs.FRMW.txCode = uint32([hex2dec('959AA9A5'),hex2dec('2A55A665'),0,0]);
elseif len == 64
    txregs.FRMW.txCode = uint32([hex2dec('6569656A'),hex2dec('959A6AA6'),0,0]);
end

txregs.GNRL.sampleRate = uint8(8);
txregs.FRMW.coarseSampleRate = uint8(txregs.GNRL.sampleRate./decRatio);
txregs.GNRL.codeLength = uint8(len);


end

