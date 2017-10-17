function test_confBlock
%%
fw = Firmware();
regs = fw.getRegs();
luts = fw.getLuts();
%%
maxPeak=0:2^6-1;
dutyCycle=maxPeak*0;
psnr=maxPeak*0;

regs.DEST.confactIn = auxpt2x0dxS(0,0,31,63);
regs.DEST.confactOt = auxpt2x0dxUS(0,0,63,255);


maxPeak2conf = [maxPeak;Pipe.DEST.confBlock(dutyCycle,psnr,maxPeak, regs)]
%%

dutyCycle=0:2^4-1;
maxPeak=dutyCycle*0;
psnr=dutyCycle*0;
validDepth=dutyCycle*0;
dutyCycle2conf = [dutyCycle;Pipe.DEST.confBlock(dutyCycle,psnr,maxPeak,validDepth, regs)];

psnr=0:2^6-1;
dutyCycle=psnr*0;
maxPeak=psnr*0;
validDepth=psnr*0;
psnr2conf = [psnr;Pipe.DEST.confBlock(dutyCycle,psnr,maxPeak,validDepth, regs)];

validDepth=[0 1];
psnr=validDepth*0;
dutyCycle=validDepth*0;
maxPeak=validDepth*0;
validDepth2conf = [validDepth;Pipe.DEST.confBlock(dutyCycle,psnr,maxPeak,validDepth, regs)];



subplot(411)
plot(maxPeak2conf(1,:),maxPeak2conf(2,:))
subplot(412)
plot(dutyCycle2conf(1,:),dutyCycle2conf(2,:))
subplot(413)
plot(psnr2conf(1,:),psnr2conf(2,:))
subplot(414)
plot(validDepth2conf(1,:),validDepth2conf(2,:))

end

function outRegs = auxpt2x0dxS(x0,y0,x1,y1) %#ok
a = (y1-y0)/(x1-x0);
b = y0-a*x0;
t0 = (-128-b)/a;
dt = 255/a;
outRegs = int16([t0 dt]);
disp([dec2hex(typecast(outRegs(1),'uint16'),4) dec2hex(typecast(outRegs(2),'uint16'),4)]);
end

function outRegs = auxpt2x0dxUS(x0,y0,x1,y1)%#ok
a = (y1-y0)/(x1-x0);
b = y0-a*x0;
t0 = (0-b)/a;
dt = 255/a;
outRegs = int16([t0 dt]);
disp([dec2hex(typecast(outRegs(1),'uint16'),4) dec2hex(typecast(outRegs(2),'uint16'),4)]);
end