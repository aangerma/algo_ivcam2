function [w] = biltW_typeIdentical( IRSM , mRegs, mLuts)

IR = uint16(IRSM(1:9));
mIR = uint16(IRSM(10));

sAdaptive = (bitand(mRegs.biltAdapt, 1) ~= 0);
rAdaptive = (bitand(mRegs.biltAdapt, 2) ~= 0);

sSharpness = uint8(mRegs.biltSharpnessS); % 6bit:  0=min, 16=default, 64=max
rSharpness = uint8(mRegs.biltSharpnessR); % 6bit:  0=min, 16=default, 64=max

if (sAdaptive)
	sIR = min(bitshift(mIR, -6), 63); % 12bit -> 6bit
else
	sIR = uint16(16);
end
wSide = mLuts.biltSpat(min(bitshift(sIR * sSharpness, -4), 63)+1); % biltSpat: 6bit -> 4bit

wDiag = bitshift(wSide .* uint16(mRegs.biltDiag), -4); % regs.biltDiag: 5bit, 0=min, 16=same as wSide, >16 do not use
wCentral = 255 - bitshift(wSide + wDiag, 2); % 128 - 4*wSide - 4*wDiag
ws = uint8([wDiag, wSide, wDiag, wSide, wCentral, wSide, wDiag, wSide, wDiag]);

% radiometric weights
dIR = min(abs(int16(IR) - int16(mIR)), 1023); % 10bit
		
% 10bit*8bit*6bit -> 8bit
if (rAdaptive)
	rIR = min(bitshift(mIR,-6), 63);  % 12bit -> 6bit
else
	rIR = 0;
end

rd = bitshift(uint32(dIR)*uint32(mLuts.biltAdaptR(rIR+1)) * uint32(rSharpness), -(6 + 5));
wr = mLuts.biltSigmoid(min(rd, uint32(63))+1);
		
wOrg = uint16(ws) .* uint16(wr);
wSum = sum(uint32(wOrg), 'native');

sFactorDenom = single(1) / single(wSum);
sFactor = uint32(floor(single(2^(8 + 20)) * sFactorDenom)); % 8bit weigths + 20 bit extra precision

w = uint8(bitshift(uint64(wOrg) .* uint64(sFactor) + 0, -20));
sum8 = sum(w, 'native')-w(5);
w(5) = 256 - uint8(sum8);

end

