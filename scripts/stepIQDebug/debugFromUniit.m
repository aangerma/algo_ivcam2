res = [480,640];
% res = [480,640];
titlestr = 'FW 221';
hw = HWinterface;
% hw.cmd('mwd b0010000 b0010004 00002201');
hw.cmd('dirtybitbypass');
% hw.cmd('ALGO_THERMLOOP_MODE_SET 0 0');
hw.startStream(0,res);
% hw.setReg('tmptroffset',single(5.841514));
hw.shadowUpdate;
hw.cmd('PIXEL_INVALIDATION_BYPASS 1');
params = Validation.aux.defaultMetricsParams;
params.roi = 1;
params.roiCropRect = 0;
params.camera.zMaxSubMM = 4;
params.camera.K = hw.getIntrinsics;
N = 50;
frames = hw.getFrame(N);


frames = hw.getFrame(N,0,1);
indices = round(res(1)/2-20):round(res(1)/2+20);
indices = 1:res(1);
for i = 1:numel(frames)
    z = zeros(res);
    z(indices,:) = frames(i).z(indices,:);
    frames(i).z = z;
end
[score,~,dbg] = Validation.metrics.planeFit(frames,params);


figure,
subplot(121);
imagesc(dbg.distIm(:,:,end),[-10,10])
subplot(122);
plot(mean(dbg.distIm(indices,:,end)));
hold on
plot([res(2)-80,res(2)-80],minmax(mean(dbg.distIm(indices,:,end))));
title(titlestr)