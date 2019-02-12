fw = Pipe.loadFirmware('C:\temp\unitCalib\F8480012\PC27\AlgoInternal');
% fw = Pipe.loadFirmware('C:\temp\unitCalib\F8320235\PC59\AlgoInternal');
[regs,luts] = fw.get();
hw = HWinterface;
hw.startStream;
% hw.setReg('jfilbypass$',1);
hw.cmd('ALGO_THERMLOOP_EN 0');
% hw.setReg('DIGGundistBypass',1);
% hw.setReg('DESTbaseline$',single(0));
% hw.setReg('DESTbaseline2$',single(0));
% hw.setReg('DESTdepthAsRange',true);
hw.setReg('DESTtmptrOffset',single(0));
hw.setReg('JFILinvBypass',true);
hw.cmd('mwd a0020c00 a0020c04 019002EE // DIGGsphericalScale');
% hw.cmd('mwd a0020a6c a0020a70 01000100 // DIGGgammaScale');
hw.shadowUpdate;

frames = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[0.6 0 0; 0 0.6 0; 0 0 1],'DFZ Validation image');
hw.read('DESTtmptrOffset')
r=Calibration.RegState(hw);
r.add('DIGGsphericalEn',true);
r.add('DESTdepthAsRange',true);
r.set();
pause(0.3);
framesSpherical = hw.getFrame(45);

% figure, tabplot; imagesc(frames.i);tabplot; imagesc(framesSpherical.i)
regs.DEST.depthAsRange=true;
regs.DEST.baseline = single(0);
regs.DEST.baseline2 = single(0);
regs.DIGG.sphericalEn=0;
regs.DIGG.sphericalScale(1) = 750;
regs.DIGG.sphericalScale(2) = 400;

r.reset();