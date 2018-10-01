fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initScript');
regs= fw.get();
fw.genMWDcmd('DESTconf|shadow','binaryTrainedConf.txt')
[ir,maxpeaks] = meshgrid(linspace(0,4000,64),0:63);
ir = double(int32(ir(:)));
maxpeaks = maxpeaks(:);
dc = 15*ones(size(maxpeaks));
psnr = 0*ones(size(maxpeaks));



% removing the redundency in Dor's configuration
[ confOut ] = Pipe.DEST.confBlock( dc, psnr, maxpeaks,ir,  regs )
% 1. Multiplying the first activation result.
regs.DEST.confactIn = int16([regs.DEST.confactIn(1)+regs.DEST.confactIn(2)/4 regs.DEST.confactIn(2)/2]);
% 2. removing w2 branch
regs.DEST.confw2 = int8([0,0,0,0]);
regs.DEST.confq(2) = 0;
[ confOut2 ] = Pipe.DEST.confBlock( dc, psnr, maxpeaks,ir,  regs )

% Result is currently r/1024+8 \(where r is the input to second activation)
% I want the second channel to by 'binary' to differ between psnr of 0 and
% other. This means the first activation width should have a smaller width of 1012 (for now),
% so I should fix w1, v1 and the first activation so the result will
% approximately stay the same. 

regs.DEST.confw1 = regs.DEST.confw1/4;
regs.DEST.confv(1) = regs.DEST.confv(1)/4;
regs.DEST.confactIn = regs.DEST.confactIn/4;
[ confOut3 ] = Pipe.DEST.confBlock( dc, psnr, maxpeaks,ir,  regs )

% Scale down second activation as well
regs.DEST.confq = regs.DEST.confq/1;
regs.DEST.confv(3) = regs.DEST.confv(3)/1;
regs.DEST.confactOt = regs.DEST.confactOt/1;
[ confOut4 ] = Pipe.DEST.confBlock( dc, psnr, maxpeaks,ir,  regs )

% Add second channel to depress small max peak.
regs.DEST.confw2 = int8([0,0,128,0]);
regs.DEST.confv(2) = 61;
regs.DEST.confq(2) = 128;
regs.DEST.confactOt = [regs.DEST.confactOt(1)+127^2, regs.DEST.confactOt(2)];
[ confOut4 ] = Pipe.DEST.confBlock( dc, psnr, maxpeaks,ir,  regs )

maxpeaks = reshape(maxpeaks,64,64);
ir = reshape(ir,64,64);

tabplot;
mesh(maxpeaks,ir,reshape(confOut,64,64));
xlabel('maxpeaks');ylabel('ir');
axis([0 64 0 64 0 15]);
tabplot;
mesh(maxpeaks,ir,reshape(confOut2,64,64));
xlabel('maxpeaks');ylabel('ir');
axis([0 64 0 64 0 15]);
tabplot;
mesh(maxpeaks,ir,reshape(confOut3,64,64));
xlabel('maxpeaks');ylabel('ir');
axis([0 64 0 64 0 15]);
tabplot;
mesh(maxpeaks,ir,reshape(confOut4,64,64));
xlabel('maxpeaks');ylabel('ir');
axis([0 64 0 64 0 15]);

fw.setRegs(regs,'');
fw.get();
fw.genMWDcmd('DESTconf|shadow','binaryTrainedConfModifiedToRemoveMaxPeak0.txt')