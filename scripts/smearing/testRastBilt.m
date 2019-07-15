dI = 6;
dI = dI*16;

dIR = 0:2^12-1;
rIR = 0;
rSharpness = 2;

rdI = bitshift(uint32(dI)*uint32(mLuts.biltAdaptR(rIR+1)) * uint32(rSharpness), -(6 + 5));

rd = bitshift(uint32(dIR)*uint32(mLuts.biltAdaptR(rIR+1)) * uint32(rSharpness), -(6 + 5));
wr = mLuts.biltSigmoid(min(rd, uint32(63))+1);


figure,plot(dIR/16,rd+1)
figure,plot(dIR/16,wr)

figure; plot(min(rd, uint32(63)