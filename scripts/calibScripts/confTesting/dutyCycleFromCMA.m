mRegs = regs.RAST;

assert(max(cmaOut(:))<128);
% confDC computation
confSum = reshape(sum(uint32(cmaOut), 1, 'native'), [480,640]);

dcCodeNorm = uint64(regs.RAST.dcCodeNorm); %dcCodeNorm = uint64(single(2^22)/single(K))

imgTxRx = 0;
invalidTxRx = (imgTxRx == 3);
imgTxRx(invalidTxRx) = 0;
dcLevel = int16(mRegs.dcLevel);
imgDcLevel = map(dcLevel, imgTxRx+1);

diffDC = min(63, abs(int16(bitshift((uint64(confSum)*dcCodeNorm), -22))-imgDcLevel));
%diffDC(confSum == 0) = 63;

%lutConf = round((-tanh(((0:63)-6)/4.2)+1)*8.0);
%lutConf = min(uint8(lutConf), 15);
lutConf = regs.RAST.confDC;

%confDC = uint8(15-min(15, bitshift(diffDC, -1)));
confDC = map(lutConf, diffDC+1);
confDC(invalidTxRx) = 0;

dutyCycle = confDC;

%% Take the peak val norm and the duty cycle and create a 2D histogram.
data = [peak_val_norm(:),dutyCycle(:)];
hist3(double(data),'Ctrs',{0:63 0:15})
xlabel('peak_val_norm');
ylabel('dc');
