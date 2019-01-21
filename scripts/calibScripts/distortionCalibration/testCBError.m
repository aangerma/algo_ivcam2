hw = HWinterface;
hw.getFrame;
frame = hw.getFrame(30);
params.expectedGridSize = [9,13];
params.camera.K = hw.getIntrinsics;
params.camera.zMaxSubMM = hw.z2mm;
frame.i = rot90(frame.i,2);
frame.z = rot90(frame.z,2);
cbError = calcCBError(frame,params);
figure,tabplot;imagesc(frame.i);
tabplot;mesh(cbError);colorbar
