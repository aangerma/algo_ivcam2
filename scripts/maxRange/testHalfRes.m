hw = HWinterface;
hw.cmd('DIRTYBITBYPASS');
hw.startStream;

frame = hw.getFrame(10);
figure,imagesc(frame.i);

setHalfRes( hw ,0);

frameHR = hw.getFrame(10);
figure,imagesc(frameHR.i);