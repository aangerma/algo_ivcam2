

low = 50;
high = 150;

fw = Pipe.loadFirmware('../../+Calibration/releaseConfigCalibVGA');
regs = fw.get();
scaleOut = int16(1024*255/(high-low));
offsetOut = -int16(low*single(scaleOut)/1024);
regsNew.JFIL.gammaScale = regs.JFIL.gammaScale;
regsNew.JFIL.gammaShift = regs.JFIL.gammaShift;
regsNew.JFIL.gammaScale(2) = scaleOut;
regsNew.JFIL.gammaShift(2) = offsetOut;
fw.setRegs(regsNew,'');
fw.genMWDcmd('JFILgammaScale|JFILgammaShift|EXTLauxShadowUpdateFrame','preset2irStrecth.txt');