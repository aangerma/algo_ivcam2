hw = HWinterface;
hw.cmd('dirtybitbypass');
hw.startStream;

frame = hw.getFrame(10);
frame = hw.getFrame(10);

hw.stopStream;
runParams.rgb = 1;
Calibration.aux.startHwStream(hw,runParams);

frameRGB = hw.getFrame(10);
frameRGB = hw.getFrame(10);

figure,imagesc((single(frame.z) - single(frameRGB.z))/4,[-5,5]),colorbar