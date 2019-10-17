hw = HWinterface;

frame = hw.getFrame(10);
frame = hw.getFrame(10);

pts = CBTools.findCheckerboardFullMatrix(frame.i,1);

figure;
tabplot;
imagesc(frame.i);
hold on
plot(pts(:,:,1),pts(:,:,2),'ro');

figure,
for i = 1:2
    hw.setPresetControlState(i);
    pause(0.5);
    frame = hw.getFrame(10);
    B = adapthisteq(frame.i,'distribution','exponential');
    pts = CBTools.findCheckerboardFullMatrix(B,1);
    tabplot;
    imagesc(B);
    hold on
    plot(pts(:,:,1),pts(:,:,2),'ro');
end



fw = Pipe.loadFirmware('../../+Calibration/releaseConfigCalibVGA');
regs = fw.get();
low = 50;
high = 150;
scaleOut = int16(1024*255/(high-low));
offsetOut = -int16(low*single(scaleOut)/1024);
regsNew.JFIL.gammaScale = regs.JFIL.gammaScale;
regsNew.JFIL.gammaShift = regs.JFIL.gammaShift;
regsNew.JFIL.gammaScale(2) = scaleOut;
regsNew.JFIL.gammaShift(2) = offsetOut;
fw.setRegs(regsNew,'');
fw.genMWDcmd('JFILgammaScale|JFILgammaShift|EXTLauxShadowUpdateFrame','preset2irStrecth.txt');

